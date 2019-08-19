# =============================================================================
# File Name: Office 365 Breach Tool.ps1
# =============================================================================
# Name: Office 365 Breach Tool
# Author: Zak Clifford 
# Contact:  z.clifford[at]computeam.co.uk
# Version 1.0
# Created: 19 Aug 2019
# Updated: N/A
# Description: Checks all Office 365 User for known compromised indicators
# SHA256 HASH: 
# =============================================================================
# Function Change Log
# v1.0 - Creation of script
# =============================================================================
$ver = "1.0"

# =============================================================================
# START OF CODE
# =============================================================================


##Start of Script

##Input Options
$CompanyName = Read-Host 'Please enter Company Name'
$SaveDir = Read-Host 'Please input the REMOTE directory where you want the files saved. If there is none please input a slash'

##Provide the credentials of the Global Administrator
$creds = Get-Credential

##Sets the exection of script in powershell
Set-ExecutionPolicy Unrestricted -Force

##Create the session by prompting for Office365 Admin Credentials
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $creds -Authentication Basic -AllowRedirection

##Import the above session
Import-PSSession $session

## List mailboxes with their forwarders and exports to a csv
Get-Mailbox -ResultSize Unlimited |  Where-Object {$_.ForwardingSmtpAddress -ne $null} | select UserPrincipalName,ForwardingSmtpAddress,DeliverToMailboxAndForward | Export-Csv -Path "$SaveDir$CompanyName SMTP_Forwarders.csv"

## Lists Inbox Rules for All Users
Get-Mailbox -ResultSize Unlimited | % { Get-InboxRule -Mailbox $_.Alias | Select Enabled,Name,Priority,From,SentTo,CopyToFolder,DeleteMessage,ForwardTo,MarkAsRead,MoveToFolder,RedirectTo,@{Expression={$_.SendTextMessageNotificationTo};Label="SendTextMessageNotificationTo"},MailboxOwnerId } | Export-Csv "$SaveDir$CompanyName Inbox_Rules.csv" -NoTypeInformation

##This creates a CSV for any newly created users in the last 7 days, this can be changed if needs be.
Get-User -ResultSize Unlimited | where {$_.WhenCreated -gt (get-date).adddays(-7)} | ft Name,whenCreated –Autosize | Export-Excel "$SaveDir$CompanyName Newly_Created_Users.xlsx"

## Connects to MSOnline and prompts for credentials again
Connect-MsolService -Credential $creds

##Creates a list of all global admins in the tenancy
$O365ROLE = Get-MsolRole -RoleName “Company Administrator”

Get-MsolRoleMember -RoleObjectId $O365ROLE.ObjectId | Export-Csv "$SaveDir$CompanyName Global_Admins.csv"

##End of Script
