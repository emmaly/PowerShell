[CmdletBinding()]
Param(
  [ValidateRange(0, [uint]::MaxValue)]
  [Nullable[uint]]$MouseTrails=$null,

  [ValidateRange(1, 20)]
  [Nullable[int]]$MouseSpeed=$null,

  [ValidateRange(0, [uint]::MaxValue)]
  [Nullable[uint]]$WheelScrollLines=$null,

  [ValidateRange(0, [uint]::MaxValue)]
  [Nullable[uint]]$WheelScrollChars=$null,

  [Nullable[bool]]$ScreensaverActive=$null,

  [Nullable[bool]]$ScreensaverSecure=$null,

  [ValidateRange(0, [uint]::MaxValue)]
  [Nullable[uint]]$ScreensaverTimeout=$null
)

BEGIN {
  [Nullable[bool]]$ScreensaverRunning = $null

  $Changes = $false
  
  Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class U32SPIGetUint {
      [DllImport("user32.dll", SetLastError = true)]
      public static extern bool SystemParametersInfo(
        uint uiAction,
        uint uiParam,
        ref uint pvParam,
        uint fWinIni
      );
    }

    public class U32SPISetUint {
      [DllImport("user32.dll", SetLastError = true)]
      public static extern bool SystemParametersInfo(
        uint uiAction,
        uint uiParam,
        uint pvParam,
        uint fWinIni
      );
    }

    public class U32SPIGetBool {
      [DllImport("user32.dll", SetLastError = true)]
      public static extern bool SystemParametersInfo(
        uint uiAction,
        bool uiParam,
        ref bool pvParam,
        uint fWinIni
      );
    }

    public class U32SPISetBool {
      [DllImport("user32.dll", SetLastError = true)]
      public static extern bool SystemParametersInfo(
        uint uiAction,
        bool uiParam,
        bool pvParam,
        uint fWinIni
      );
    }

    public class U32SPISendMessage {
      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult
      );

      public const uint HWND_BROADCAST = 0xffff;
      public const uint WM_SETTINGCHANGE = 0x001A;
      public const uint SMTO_ABORTIFHUNG = 0x0002;
    }

    public class U32SPI {
      public const uint SPI_UPDATEINIFILE = 0x0001;
      public const uint SPI_SENDCHANGE = 0x0002;

      public const uint SPI_GETMOUSETRAILS = 0x005E;
      public const uint SPI_SETMOUSETRAILS = 0x005D;
      public const uint SPI_GETMOUSESPEED = 0x0070;
      public const uint SPI_SETMOUSESPEED = 0x0071;
      public const uint SPI_GETWHEELSCROLLLINES = 0x0068;
      public const uint SPI_SETWHEELSCROLLLINES = 0x0069;
      public const uint SPI_GETWHEELSCROLLCHARS = 0x006C;
      public const uint SPI_SETWHEELSCROLLCHARS = 0x006D;

      public const uint SPI_GETSCREENSAVERRUNNING = 0x0072;
      public const uint SPI_SETSCREENSAVEACTIVE = 0x0011;
      public const uint SPI_GETSCREENSAVEACTIVE = 0x0010;
      public const uint SPI_SETSCREENSAVESECURE = 0x0077;
      public const uint SPI_GETSCREENSAVESECURE = 0x0076;
      public const uint SPI_GETSCREENSAVETIMEOUT = 0x000E;
      public const uint SPI_SETSCREENSAVETIMEOUT = 0x000F;

      public static bool GetUint(
        uint uiAction,
        uint uiParam,
        ref uint pvParam
      ) {
        return U32SPIGetUint.SystemParametersInfo(
          uiAction,
          uiParam,
          ref pvParam,
          0
        );
      }

      public static bool SetUint(
        uint uiAction,
        uint uiParam,
        uint pvParam,
        uint fWinIni
      ) {
        return U32SPISetUint.SystemParametersInfo(
          uiAction,
          uiParam,
          pvParam,
          fWinIni
        );
      }

      public static bool GetBool(
        uint uiAction,
        bool uiParam,
        ref bool pvParam
      ) {
        return U32SPIGetBool.SystemParametersInfo(
          uiAction,
          uiParam,
          ref pvParam,
          0
        );
      }

      public static bool SetBool(
        uint uiAction,
        bool uiParam,
        bool pvParam,
        uint fWinIni
      ) {
        return U32SPISetBool.SystemParametersInfo(
          uiAction,
          uiParam,
          pvParam,
          fWinIni
        );
      }

      public static IntPtr BroadcastSettingChange(
        out UIntPtr lpdwResult
      ) {
        return U32SPISendMessage.SendMessageTimeout(
          (IntPtr)U32SPISendMessage.HWND_BROADCAST,
          U32SPISendMessage.WM_SETTINGCHANGE,
          UIntPtr.Zero,
          "Environment",
          U32SPISendMessage.SMTO_ABORTIFHUNG,
          100,
          out lpdwResult
        );
      }
    }
"@
}

PROCESS {
  if ($MouseTrails -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting MouseTrails to $MouseTrails"
    if ([U32SPI]::SetUint([U32SPI]::SPI_SETMOUSETRAILS, $MouseTrails, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set MouseTrails"
    }
  }

  if ($MouseSpeed -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting MouseSpeed to $MouseSpeed"
    if ([U32SPI]::SetUint([U32SPI]::SPI_SETMOUSESPEED, 0, $MouseSpeed, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set MouseSpeed"
    }
  }

  if ($WheelScrollLines -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting WheelScrollLines to $WheelScrollLines"
    if ([U32SPI]::SetUint([U32SPI]::SPI_SETWHEELSCROLLLINES, $WheelScrollLines, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set WheelScrollLines"
    }
  }

  if ($WheelScrollChars -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting WheelScrollChars to $WheelScrollChars"
    if ([U32SPI]::SetUint([U32SPI]::SPI_SETWHEELSCROLLCHARS, $WheelScrollChars, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set WheelScrollChars"
    }
  }

  if ($ScreensaverActive -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting ScreensaverActive to $ScreensaverActive"
    if ([U32SPI]::SetBool([U32SPI]::SPI_SETSCREENSAVEACTIVE, $ScreensaverActive, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set ScreensaverActive"
    }
  }

  if ($ScreensaverSecure -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting ScreensaverSecure to $ScreensaverSecure"
    if ([U32SPI]::SetBool([U32SPI]::SPI_SETSCREENSAVESECURE, $ScreensaverSecure, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set ScreensaverSecure"
    }
  }

  if ($ScreensaverTimeout -ne $null) {
    $fWinIni = [U32SPI]::SPI_UPDATEINIFILE -bor [U32SPI]::SPI_SENDCHANGE
    Write-Host "Setting ScreensaverTimeout to $ScreensaverTimeout"
    if ([U32SPI]::SetUint([U32SPI]::SPI_SETSCREENSAVETIMEOUT, $ScreensaverTimeout, $null, $fWinIni)) {
      $Changes = $true
    } else {
      Write-Host "Failed to set ScreensaverTimeout"
    }
  }

  if (-not [U32SPI]::GetUint([U32SPI]::SPI_GETMOUSETRAILS, 0, [ref]$MouseTrails)) {
    $MouseTrails = $null
    Write-Host "Failed to get MouseTrails"
  }

  if (-not [U32SPI]::GetUint([U32SPI]::SPI_GETMOUSESPEED, 0, [ref]$MouseSpeed)) {
    $MouseSpeed = $null
    Write-Host "Failed to get MouseSpeed"
  }

  if (-not [U32SPI]::GetUint([U32SPI]::SPI_GETWHEELSCROLLLINES, 0, [ref]$WheelScrollLines)) {
    $WheelScrollLines = $null
    Write-Host "Failed to get WheelScrollLines"
  }

  if (-not [U32SPI]::GetUint([U32SPI]::SPI_GETWHEELSCROLLCHARS, 0, [ref]$WheelScrollChars)) {
    $WheelScrollChars = $null
    Write-Host "Failed to get WheelScrollChars"
  }

  if (-not [U32SPI]::GetBool([U32SPI]::SPI_GETSCREENSAVEACTIVE, 0, [ref]$ScreensaverActive)) {
    $ScreensaverActive = $null
    Write-Host "Failed to get ScreensaverActive"
  }

  if (-not [U32SPI]::GetBool([U32SPI]::SPI_GETSCREENSAVESECURE, 0, [ref]$ScreensaverSecure)) {
    $ScreensaverSecure = $null
    Write-Host "Failed to get ScreensaverSecure"
  }

  if (-not [U32SPI]::GetUint([U32SPI]::SPI_GETSCREENSAVETIMEOUT, 0, [ref]$ScreensaverTimeout)) {
    $ScreensaverTimeout = $null
    Write-Host "Failed to get ScreensaverTimeout"
  }

  if (-not [U32SPI]::GetBool([U32SPI]::SPI_GETSCREENSAVERRUNNING, 0, [ref]$ScreensaverRunning)) {
    $ScreensaverRunning = $null
    Write-Host "Failed to get ScreensaverRunning"
  }

  if ($Changes) {
    $lpdwResult = [UintPtr]::Zero
    if (-not [U32SPI]::BroadcastSettingChange([ref]$lpdwResult)) {
      Write-Host "Failed to broadcast setting change"
    }
  }

  [PSCustomObject]@{
    MouseTrails = $MouseTrails
    MouseSpeed = $MouseSpeed
    WheelScrollLines = $WheelScrollLines
    WheelScrollChars = $WheelScrollChars
    ScreensaverActive = $ScreensaverActive
    ScreensaverSecure = $ScreensaverSecure
    ScreensaverTimeout = $ScreensaverTimeout
    ScreensaverRunning = $ScreensaverRunning
  }
}

END {}