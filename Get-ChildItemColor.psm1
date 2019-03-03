$OriginalForegroundColor = $Host.UI.RawUI.ForegroundColor
if ([System.Enum]::IsDefined([System.ConsoleColor], 1) -eq "False") { $OriginalForegroundColor = "Gray" }

$CompressedList = @(".7z", ".gz", ".jar", ".nupkg", ".rar", ".tar", ".tgz", ".zip")
$ExecutableList = @(".exe", ".bat", ".cmd", ".csx", ".lua", ".mk", ".py", ".pl", ".ps1",
    ".vbs", ".rb", ".reg", ".fsscript", ".fsx", ".sh", ".w32")
$DllPdbList = @(".dll", ".lib", ".o", ".obj", ".pdb", ".psm1")
$TextList = @(".csv", ".log", ".markdown", ".md", ".rst", ".txt")
$ConfigsList = @(".bash_profile", ".bashrc", ".cfg", ".conf", ".config", ".csproj", ".dbproj", 
    ".editorconfig", ".fsproj", ".gitattributes", ".gitconfig", ".gitignore", ".ini", ".json", 
    ".npmrc", ".nuspec", ".psd1", ".resx", ".suo", ".toml", ".vbproj", ".vcproj", ".vcxproj", 
    ".viminfo", ".xml", ".yaml", ".yml")
$CodeList = @(".asax", ".asp", ".aspx", ".c", ".class", ".cpp", ".cshtml", ".css", ".cxx", 
    ".dbml", ".diff", ".dpj", ".dtd", ".edmx", ".fs", ".fsi", ".h", ".hh", ".hdl", ".hpp", ".hrc", 
    ".html", ".hxx", ".inc", ".inl", ".java", ".js", ".jsp", ".jspf", ".jsx", ".less", ".map", ".sass", 
    ".scss", ".sln", ".snippet", ".sql", ".ts", ".vb", ".vbg", ".vbx", ".vbz", ".xaml")

$ColorTable = @{}

$ColorTable.Add('Default', $OriginalForegroundColor) 
$ColorTable.Add('Directory', "Green") 

ForEach ($Extension in $CompressedList) {
    $ColorTable.Add($Extension, "Yellow")
}

ForEach ($Extension in $ExecutableList) {
    $ColorTable.Add($Extension, "Blue")
}

ForEach ($Extension in $TextList) {
    $ColorTable.Add($Extension, "Cyan")
}

ForEach ($Extension in $DllPdbList) {
    $ColorTable.Add($Extension, "DarkGreen")
}

ForEach ($Extension in $ConfigsList) {
    $ColorTable.Add($Extension, "DarkYellow")
}

ForEach ($Extension in $CodeList) {
    $ColorTable.Add($Extension, "DarkCyan")
}

Function Get-Color($Item) {
    $Key = 'Default'

    If ($Item.GetType().Name -eq 'DirectoryInfo') {
        $Key = 'Directory'
    }
    Else {
        If ($Item.PSobject.Properties.Name -contains "Extension") {
            If ($ColorTable.ContainsKey($Item.Extension)) {
                $Key = $Item.Extension
            }
        }
    }

    $Color = $ColorTable[$Key]
    Return $Color
}


Function Get-ChildItemColor {
    Param(
        [string]$Path = ""
    )
    $Expression = "Get-ChildItem -Path `"$Path`" $Args"

    $Items = Invoke-Expression $Expression

    ForEach ($Item in $Items) {
        $Color = Get-Color $Item

        $Host.UI.RawUI.ForegroundColor = $Color
        $Item
        $Host.UI.RawUI.ForegroundColor = $OriginalForegroundColor
    }
}

Function Get-ChildItemColorFormatWide {
    Param(
        [string]$Path = "",
        [switch]$Force
    )

    $nnl = $True

    $Expression = "Get-ChildItem -Path `"$Path`" $Args"

    if ($Force) {$Expression += " -Force"}

    $Items = Invoke-Expression $Expression

    $lnStr = $Items | Select-Object Name | Sort-Object { "$_".Length } -Descending | Select-Object -First 1
    $len = $lnStr.Name.Length
    $width = $Host.UI.RawUI.WindowSize.Width
    $cols = If ($len) {[math]::Floor(($width + 1) / ($len + 2))} Else {1}
    if (!$cols) {$cols = 1}

    $i = 0
    $pad = [math]::Ceiling(($width + 2) / $cols) - 3

    ForEach ($Item in $Items) {
        If ($Item.PSobject.Properties.Name -contains "PSParentPath") {
            If ($Item.PSParentPath -match "FileSystem") {
                $ParentType = "Directory"
                $ParentName = $Item.PSParentPath.Replace("Microsoft.PowerShell.Core\FileSystem::", "")
            }
            ElseIf ($Item.PSParentPath -match "Registry") {
                $ParentType = "Hive"
                $ParentName = $Item.PSParentPath.Replace("Microsoft.PowerShell.Core\Registry::", "")
            }
        }
        Else {
            $ParentType = ""
            $ParentName = ""
            $LastParentName = $ParentName
        }

        $Color = Get-Color $Item

        If ($LastParentName -ne $ParentName) {
            If ($i -ne 0 -AND $Host.UI.RawUI.CursorPosition.X -ne 0) {
                # conditionally add an empty line
                Write-Host ""
            }
            Write-Host -Fore $OriginalForegroundColor ("`n   $($ParentType): $ParentName`n")
        }

        $nnl = ++$i % $cols -ne 0

        # truncate the item name
        $toWrite = $Item.Name
        If ($toWrite.length -gt $pad) {
            $toWrite = $toWrite.Substring(0, $pad - 3) + "..."
        }

        Write-Host ("{0,-$pad}" -f $toWrite) -Fore $Color -NoNewLine:$nnl

        If ($nnl) {
            Write-Host "  " -NoNewLine
        }

        $LastParentName = $ParentName
    }

    If ($nnl) {
        # conditionally add an empty line
        Write-Host ""
        Write-Host ""
    }
}

Export-ModuleMember -Function 'Get-*'
