Param($Path)

#####################################################################
# 文字列をバイト配列にする
#####################################################################
function String2Byte( $String ){
	$Byte = [System.Text.Encoding]::UTF8.GetBytes($String)
	return $Byte
}

#####################################################################
# バイト配列を文字列にする
#####################################################################
function Byte2String( $Byte ){
	$String = [System.Text.Encoding]::UTF8.GetString($Byte)
	return $String
}

#####################################################################
# Base64 をバイト配列にする
#####################################################################
function Base642Byte( $Base64 ){
	$Byte = [System.Convert]::FromBase64String($Base64)
	return $Byte
}

#####################################################################
# バイト配列を Base64 にする
#####################################################################
function Byte2Base64( $Byte ){
	$Base64 = [System.Convert]::ToBase64String($Byte)
	return $Base64
}



##################################################
# セッション鍵生成
##################################################
function CreateRandomKey( $BitSize ){
    if( ($BitSize % 8) -ne 0 ){
        echo "Key size Error"
        return $null
    }
    # アセンブリロード
    Add-Type -AssemblyName System.Security

    # バイト数にする
    $ByteSize = $BitSize / 8

    # 入れ物作成
    $KeyBytes = New-Object byte[] $ByteSize

    # オブジェクト 作成
    $RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    # 鍵サイズ分の乱数を生成
    $RNG.GetNonZeroBytes($KeyBytes)

    # オブジェクト削除
    $RNG.Dispose()

    return $KeyBytes
}


##################################################
# main
##################################################

if( $Path -eq $null ){
	echo "Usage..."
	echo " .\make256key.ps1 -Path KeyFile"
	exit
}


# 256 バイトの共通鍵生成
$ByteKey = CreateRandomKey 256


# Base 64 にする
$Base64Key = Byte2Base64 $ByteKey

# ファイル出力
Set-Content -Path $Path -Value $Base64Key -Encoding UTF8
