
####################################  SCRIPT PERMETTANT DE CRYPTER LE MOT DE PASSE ####################################################
#
#                            LE MOT DE PASSE EST SAUVEGARDE SUR UN FICHIER KEY et CRYPTE
#
#              CELA PERMET UNE AUTO-AUTHENTIFICATION A EXHANGE ONLINE ET QUE LE SCRIPT SOIT AUTOMNOME 
#  
#                     IL EST POSSIBLE DE FAIRE UNE AUTHENTIFICATION EN DONNANT SON MOT DE PASSE
Read-Host -Prompt “Entrer votre mot de passe Office365” -AsSecureString | ConvertFrom-SecureString | Out-File .\TENANTNAME.key
#
#######################################################################################################################################