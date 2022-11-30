$From = "fromemail"
$To = "toemail"
$Subject = "Test Email"
$Body = "<h2>This is a Test</h2><br><br>"
$SMTPServer = "us-smtp-outbound-1.mimecast.com"
$SMTPPort = "587"
Send-MailMessage -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -From $From -To $To -Subject $subject -BodyAsHtml $Body -Credential $from -Encoding ([System.Text.Encoding]::UTF8)
