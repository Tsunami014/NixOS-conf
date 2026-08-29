{ config, lib, pkgs, ... }:
let
  allTools = [
    "bash" "edit" "write" "read" "grep" "glob" "list" "patch"
    "todowrite" "todoread" "webfetch" "websearch" "lsp" "skill" "task"
  ];
  mkTools = allowed: builtins.listToAttrs (map (name: {
    inherit name;
    value = builtins.elem name allowed;
  }) allTools);

  baseConfig = {
    "$schema" = "https://opencode.ai/config.json";
    small_model = "ollama/qwen2.5:0.5b";
    agent = {
      chat = {
        description = "Even smaller agent for just chatting";
        mode = "primary";
        prompt = "You are an assistant. Be concise."
            + " You can use tools to view files or folder structures as you need.";
        tools = mkTools [ "read" "list" ];
      };
      lean = {
        description = "Minimal agent";
        mode = "primary";
        prompt = "You are a coding assistant. Be concise."
            + " Read files before editing them."
            + " You can use tools to view and edit files or folder structures as you need."
            + " If the user asks you to complete a task, do not stop to ask the user if you are doing it the correct way; instead, keep trying different approaches until you solve the issue.";
        tools = mkTools [ "read" "write" "edit" "list" "grep" "glob" "bash" ];
      };
    };
    default_agent = "lean";
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama";
      options.baseURL = "http://localhost:11434/v1";
    };
  };

  baseConfigFile = pkgs.writeText "opencode-base.json" (builtins.toJSON baseConfig);

  opencodeConfigDir  = "${config.xdg.configHome}/opencode";
  opencodeConfigPath = "${opencodeConfigDir}/opencode.json";

  syncScript = pkgs.writeShellScript "opencode-sync-ollama-models" ''
    set -euo pipefail
    mkdir -p "${opencodeConfigDir}"

    if tags_json=$(${pkgs.curl}/bin/curl -sf --max-time 3 http://localhost:11434/api/tags); then
      models_json=$(echo "$tags_json" | ${pkgs.jq}/bin/jq '
        { provider: { ollama: { models: (
            (.models // []) | map({ (.name): { name: .name } }) | add // {}
          ) } } }
      ')
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "${baseConfigFile}" <(echo "$models_json") \
        > "${opencodeConfigPath}.tmp"
      mv "${opencodeConfigPath}.tmp" "${opencodeConfigPath}"
    else
      echo "opencode: ollama not reachable at localhost:11434, keeping existing model list" >&2
      # first-run fallback so the file exists even if ollama was never up
      [ -f "${opencodeConfigPath}" ] || cp "${baseConfigFile}" "${opencodeConfigPath}"
    fi
  '';
in
{
  home.activation.opencodeModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${syncScript}
  '';

  home.packages = [
    (pkgs.writeShellScriptBin "opencode-refresh-models" "exec ${syncScript}")
  ];
}
