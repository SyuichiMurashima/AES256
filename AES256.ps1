##################################################
# AES256 暗号/復号
##################################################
Param($Path, $KeyPath, [switch]$Encrypto, [switch]$Decrypto)

# 暗号ファイルの拡張子
$ExtName = "aes256"

##################################################
# Base64 をバイト配列にする
##################################################
function Base642Byte( $Base64 ){
	$Byte = [System.Convert]::FromBase64String($Base64)
	return $Byte
}

##################################################
# AES 暗号化
##################################################
function AESEncrypto($KeyByte, $PlainByte){
	$KeySize = 256
	$BlockSize = 128
	$Mode = "CBC"
	$Padding = "PKCS7"

	# アセンブリロード
	Add-Type -AssemblyName System.Security

	# AES オブジェクトの生成
	$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider

	# 各値セット
	$AES.KeySize = $KeySize
	$AES.BlockSize = $BlockSize
	$AES.Mode = $Mode
	$AES.Padding = $Padding

	# IV 生成
	$AES.GenerateIV()

	# 生成した IV
	$IV = $AES.IV

	# 鍵セット
	$AES.Key = $KeyByte

	# 暗号化オブジェクト生成
	$Encryptor = $AES.CreateEncryptor()

	# 暗号化
	$EncryptoByte = $Encryptor.TransformFinalBlock($PlainByte, 0, $PlainByte.Length)

	# IV と暗号化した文字列を結合
	$DataByte = $IV + $EncryptoByte

	# オブジェクト削除
	$Encryptor.Dispose()
	$AES.Dispose()

	return $DataByte
}

##################################################
# AES 復号化
##################################################
function AESDecrypto($ByteKey, $ByteString){
	$KeySize = 256
	$BlockSize = 128
	$IVSize = $BlockSize / 8
	$Mode = "CBC"
	$Padding = "PKCS7"

	# IV を取り出す
	$IV = @()
	for( $i = 0; $i -lt $IVSize; $i++){
		$IV += $ByteString[$i]
	}

	# アセンブリロード
	Add-Type -AssemblyName System.Security

	# オブジェクトの生成
	$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider

	# 各値セット
	$AES.KeySize = $KeySize
	$AES.BlockSize = $BlockSize
	$AES.Mode = $Mode
	$AES.Padding = $Padding

	# IV セット
	$AES.IV = $IV

	# 鍵セット
	$AES.Key = $ByteKey

	# 復号化オブジェクト生成
	$Decryptor = $AES.CreateDecryptor()

	try{
		# 復号化
		$DecryptoByte = $Decryptor.TransformFinalBlock($ByteString, $IVSize, $ByteString.Length - $IVSize)
	}
	catch{
		$DecryptoByte = $null
	}

	# オブジェクト削除
	$Decryptor.Dispose()
	$AES.Dispose()

	return $DecryptoByte
}

##################################################
# main
##################################################

if( ($Path -eq $null) -or ($KeyPath -eq $null)){
	echo "Usage..."
	echo " .\aes256.ps1 [-Encrypto|-Decrypto] -Path InputFile -KeyPath KeyFile"
	exit
}

# Data
if( -not (Test-Path $Path )){
	echo "[FAIL] $Path not found."
	exit
}

# Key
if( -not (Test-Path $KeyPath )){
	echo "[FAIL] $KeyPath not found."
	exit
}

# 暗号/復号オプション
if( (($Encrypto -eq $fals) -and ( $Decrypto -eq $false)) -or `
	(($Encrypto -eq $true) -and ( $Decrypto -eq $true))){
	echo "[FAIL] select -Encrypto or -Decrypto"
	exit
}

# 鍵読み込み
$Base64Key = Get-Content $KeyPath
$ByteKey = Base642Byte $Base64Key

# 暗号化
if( $Encrypto ){

	# 暗号化ファイル名
	$EncryptoFileName = $Path + "." + $ExtName

	# データファイル読み込み
	$BytePlainData = Get-Content $Path -Encoding Byte

	# 暗号
	$ByteEncryptoData = AESEncrypto $ByteKey $BytePlainData

	# ファイル出力
	Set-Content -Path $EncryptoFileName -Value $ByteEncryptoData -Encoding Byte
}
# 復号化
else{
	# 拡張子確認
	if( $Path -notmatch $ExtName ){
		echo "[FAIL] $Path は暗号化ファイルではない"
		exit
	}

	# 復号ファイル名
	$ChangeString = "."+ $ExtName
	$DecryptoFileName = $Path.Replace($ChangeString,"")

	# 暗号ファイル読み込み
	$ByteEncryptoData = Get-Content $Path  -Encoding Byte

	# 復号
	$BytePlainData = AESDecrypto $ByteKey $ByteEncryptoData

	# 平文ファイル出力
	Set-Content -Path $DecryptoFileName -Value $BytePlainData -Encoding Byte
}
