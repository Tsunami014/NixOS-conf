{ config, lib, pkgs, master-pkgs, ... }:
let
  rule = effect: action: { inherit action effect; resource = "*"; };
  ruleOn = effect: action: resource: { inherit action effect resource; };

  baseConfig = {
    "$schema" = "https://opencode.ai/config.json";
    small_model = "ollama/qwen2.5:0.5b";
    agents = {
      chat = {
        description = "Just have a chat, nothing too complex";
        mode = "primary";
        system = "You are a concise assistant.";
        permissions =
          [ (rule "deny" "*") ]
          ++ map (rule "allow") [ "read" "edit" "glob" "grep" ]
          ++ [ (rule "ask" "shell") ]
          ++ [
            (ruleOn "allow" "edit" "*AGENTS.md")
            (ruleOn "allow" "read" "*AGENTS.md")
          ];
      };
      agentic = {
        description = "That's so agentic";
        mode = "primary";
        system = "You are a concise coding orchestrator. You do no work yourself."
          +"\nFor every request, launch subagents with the `subagent` tool."
          +" Split the work into small independent pieces and launch one subagent per piece, in parallel where possible."
          +"\nTell each subagent to write code in small chunks, and to use short scripts or commands for bulk edits, searching, or data processing."
          +"\nIf a task has three or more steps, keep a todo list with the todo tool: write it before launching subagents, and tick items off as their reports come in. Skip the list for simple tasks."
          +"\nIf you learn something durable about the project that future sessions would need (e.g. build or test commands, conventions, folder setup), add a short note to AGENTS.md."
          +" Don't log routine progress or one-off details, and ensure the file stays small."
          +"\nYour job is to launch subagents, track their reports, and verify the results before finishing."
          +"\nIf you're unsure what the user wants, try first, then ask."
        ;
        permissions =
          [ (rule "deny" "*") ]
          ++ map (rule "allow") [ "subagent" "todo*" "question" ];
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
