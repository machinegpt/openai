$OPENAI_API_KEY = "sk-010101010111010100001011010101001010101010101010"

$max_tokens = 4096

while ($true) {
    try {
        $user_input = Read-Host -Prompt "[+] Input"
        if ([string]::IsNullOrWhiteSpace($user_input)) {
            Write-Host "Please enter a valid input."
            continue
        }
        if ($user_input -eq "exit") {
            break
        }
        if ($user_input.StartsWith("file")) {
            $filePath = $user_input.Substring(4).Trim()
            if ($filePath -eq "") {
                $filePath = Read-Host -Prompt "[+] Enter file path"
            }
            if (Test-Path $filePath) {
                $user_input = Get-Content -Raw $filePath
                Write-Host "Content of the file: $user_input"
            }
            else {
                Write-Host "File not found"
                continue
            }
        }
        $max_prompt_tokens = $max_tokens - [System.Text.Encoding]::UTF8.GetByteCount($user_input) + $user_input.Split().Count
        if ($user_input) {
            $headers = @{
                "Authorization" = "Bearer $OPENAI_API_KEY"
                "Content-Encoding" = "gzip"
            }

            $body = @{
                prompt = $user_input
                model = "text-davinci-003"
                max_tokens = $max_prompt_tokens
                temperature = 1.1
                user = "user"
                echo = $false
                frequency_penalty = 0
                presence_penalty = 2
                top_p = 1
                # best_of = 2
                # n = 2
            }
        }
        Write-Host "max tokens: $max_prompt_tokens"
        Write-Host "[+] Openai: "
        $jsonBody = $body | ConvertTo-Json
        $gzipBody = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/completions" -Method POST -Body $gzipBody -Headers $headers -ContentType "application/json;charset=utf-8" -TimeoutSec 86400
        $agent_output = $response.choices.text

        if (!$agent_output.Contains("[ANSWER]")) {
            $agent_output = "`n[ANSWER]`n" + $agent_output
        }
        $agent_output += "`n[QUESTION]"
        $agent_output | Out-File -FilePath "output.txt" -Append
        Write-Host $agent_output
    } catch {
        Write-Host $_
        Add-Content -Path ".\loader.log" -Value $_
    }
}
