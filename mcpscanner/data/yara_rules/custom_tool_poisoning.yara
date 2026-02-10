rule Critical_Base64_Command_Execution {
    meta:
        description = "Detects base64 command execution in tool descriptions"
        severity = "CRITICAL"
        classification = "harmful"
        threat_type = "CODE EXECUTION"
        
    strings:
        // Base64 string pattern - matches valid base64 characters (A-Z, a-z, 0-9, +, /, =)
        // Base64 strings are typically 20+ characters and may have 0-2 padding equals signs
        $base64_string = /[A-Za-z0-9+\/]{20,}={0,2}/
        
        // Echo command with base64 string
        $echo_base64 = /echo\s+['"]?[A-Za-z0-9+\/]{20,}={0,2}['"]?\s*\|/ nocase
        
        // Base64 decode command variations
        $base64_decode = /base64\s*(--decode|-d|-D)/ nocase
        
        // Shell execution commands
        $bash_cmd = /\b(bash|sh|zsh|dash|ksh)\b/ nocase
        $shell_exec = /\|\s*(bash|sh|zsh|dash|ksh)\b/ nocase
        
        // Common instruction phrases that precede malicious commands
        $instruction_phrases = /(in\s+order\s+to|to\s+complete|run\s+this\s+command|execute\s+this|run\s+the\s+following|carry\s+out)/i
        
        // Complete pattern: echo <base64> | base64 -d | bash (most common)
        $pattern1 = /echo\s+['"]?[A-Za-z0-9+\/]{20,}={0,2}['"]?\s*\|\s*base64\s*(--decode|-d|-D)\s*\|\s*(bash|sh|zsh)/ nocase
        
        // Pattern: base64 -d <file> | bash (less common but possible)
        $pattern2 = /base64\s*(--decode|-d|-D).*\|.*(bash|sh|zsh)/ nocase
        
        // Pattern: echo <base64> | base64 | bash (without explicit decode flag)
        $pattern3 = /echo\s+['"]?[A-Za-z0-9+\/]{20,}={0,2}['"]?\s*\|\s*base64\s*\|\s*(bash|sh|zsh)/ nocase
        
        // Pattern with instruction phrases
        $pattern4 = /(in\s+order\s+to|to\s+complete|run\s+this\s+command|carry\s+out).*echo\s+[A-Za-z0-9+\/]{20,}={0,2}.*\|.*(base64|bash|sh)/i
        
        // Pattern: base64 string followed by decode and shell
        $pattern5 = /[A-Za-z0-9+\/]{30,}={0,2}.*base64.*(decode|--decode|-d).*\|.*(bash|sh|zsh)/i
        
        // Pattern: base64 string in quotes/backticks with pipe to bash
        $pattern6 = /['"`][A-Za-z0-9+\/]{30,}={0,2}['"`].*\|.*(base64|bash|sh)/i
        
        // Pattern: base64 decode piped directly to shell without echo
        $pattern7 = /base64\s*(--decode|-d|-D)\s+.*\|.*(bash|sh|zsh|exec)/ nocase
        
        // Pattern: base64 string with newlines or spaces (obfuscated)
        $pattern8 = /echo\s+[A-Za-z0-9+\/\s]{30,}={0,2}.*\|.*base64.*\|.*bash/i
        
    condition:
        // Most specific patterns first
        $pattern1 or
        $pattern2 or
        $pattern3 or
        $pattern4 or
        $pattern5 or
        $pattern6 or
        $pattern7 or
        $pattern8 or
        // Fallback: combination of components
        ($echo_base64 and $base64_decode and $bash_cmd) or
        ($base64_string and $base64_decode and $shell_exec) or
        ($instruction_phrases and $base64_string and $bash_cmd)
}

rule Command_In_Tool_Description {
    meta:
        description = "Detects tool descriptions containing command execution instructions"
        severity = "HIGH"
        classification = "harmful"
        threat_type = "CODE EXECUTION"
        
    strings:
        $run_command = /run\s+this\s+command/i
        $shell_cmd = /(echo|bash)\s+[^\s]{10,}/ nocase
        
    condition:
        all of them
}

