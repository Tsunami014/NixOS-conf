{ config, lib, pkgs, master-pkgs, ... }:
let
  rule = effect: action: { inherit action effect; resource = "*"; };

  baseConfig = {
    "$schema" = "https://opencode.ai/config.json";
    small_model = "ollama/qwen2.5:0.5b";
    agent = {
      chat = {
        description = "Just have a chat, nothing too complex";
        mode = "primary";
        prompt = "You are a concise assistant.";
        permissions =
          [ (rule "deny" "*") ]
          ++ map (rule "allow") [ "read" "edit" "glob" "grep" ]
          ++ [ (rule "ask" "shell") ];
      };
    };
    default_agent = "chat";
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama";
      options.baseURL = "http://localhost:11434/v1";
      timeout = false; # Large contexts can take a very long time
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
    master-pkgs.opencode
  ];
}
