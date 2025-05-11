# Fileserver Setup (FTP/SFTP & Samba)

W tym dokumencie opisuję konfigurację dwóch klasycznych serwerów plików:
- **FTP/SFTP** - używany do transferu plików, z rozróżnieniem na bezpieczne i niebezpieczne wersje.
- **Samba (SMB)** - popularny sposób udostępniania plików w sieciach z systemami Windows.

---

## FTP & SFTP

### Instalacja serwera `vsftpd`

```bash
sudo apt update
sudo apt install vsftpd
```

### Konfiguracja FTP (Plik: /etc/vsftpd.conf)

Tworzę kopię zapasową podstawowych ustawieć (czyli kopia pliku konfiguracyjnego):

```bash
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
```

Następnie zmieniam zmienne konfiguracyjne.\
Poniżej wszystkie zmienne konfiguracyjne pliku `vsftpd.conf`

```conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
local_root=/home/ftp_user
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000
```

Jak widać dorzuciłem pare swoich no i z local_root można wyczytać, że w folderze home pojawił się nowy folder użytkownika `ftp_user`.\
Dodałem go komendą:

```bash
sudo useradd -m ftp_user
```

To polecenie towrzy nowego użytkownika o nazwie ftp_user i tworzy katalog domowy w /home/ftp_user.

### Typowe problemy jakie napodkałem podczas konfiguracji:

1. `500 OOPS: vsftpd: refusing to run with writable root inside chroot()` występuje, ponieważ serwer vsftpd nie pozwala na zapis w katalogu, który jest ustawiony jako katalog domowy użytkownika w trybie chroot. To oznacza, że jeśli katalog użytkownika FTP (/home/ftp_user/ftp) jest ustawiony jako katalog domowy i jest zapisywalny, serwer FTP odmawia połączenia, aby uniknąć potencjalnych problemów związanych z bezpieczeństwem. Rozwiązanie:
    - sudo chmod a-w /home/ftp_user
    - sudo mkdir /home/ftp_user/upload
    - sudo chown ftp_user:ftp_user /home/ftp_user/upload
    - Jednym słowem zmieniamy katalog główny na tylko do odczytu a wewnętrzny katalog na taki w którym można zapisywać i odczytywać.
    - Dlaczego? Robimy to w ten sposób by uniknąć naruszenia uprawnień poprzez wejście do katalogu roota i odczyt wrażliwych plików i danych poprzez FTP.

### Łączenie się z naszym serwerem:

#### Poprzez FTP (Niezalecane ale możliwe):

```bash
ftp ftp_user@<IP_SERWERA>
```

W tym przypadku wszystko co przesyłamy może zostać przechwycone i odczytane przez "człowieka w środku" czyli kogoś kto nasłuchuje między klientem a serwerem.

![Sceenshot 1: MITM FTP Wireshark](/screenshots/fileserver/Screenshot%20From%202025-05-11%2016-34-02.webp)

#### Poprzez SFTP (Zalecane gdyż dane są szyfrowane):

```bash
sftp ftp_user@<IP_SERWERA>
```

W tym przypadku atakujący będzie miał dużo ciężej przechwycić dane wrażliwe bo ruch jest szyfrowany. Za konfigurację ruchu po SFTP odpowiada plik konfiguracyjny ssh.

![Sceenshot 2: MITM SFTP Wireshark](/screenshots/fileserver/Screenshot%20From%202025-05-11%2016-38-18.webp)

#### FTP przesyła hasła i dane w formie czystego tekstu (plain text), co umożliwia ich przechwycenie (np. przez Wiresharka). SFTP wykorzystuje tunel SSH i jest bezpieczny.

---

## Samba (SMB)

### Instalacja Samby:

```bash
sudo apt install samba
```

### Tworzę katalog do udostępniania:

```bash
sudo mkdir -p /srv/samba/shared
sudo chown adminuser:adminuser /srv/samba/shared
sudo chmod 2770 /srv/samba/shared
```

### Konfiguracja pliku /etc/samba/smb.conf

```conf
[Shared]
    path = /srv/samba/shared
    valid users = adminuser
    read only = no
    browsable = yes
```

### Dodanie użytkownika do Samby:

```bash
sudo smbpasswd -a adminuser
```

---

## Dodatkowa konfiguracja Samby:

### Dodanie nowego użytkownika do Samby:

1. Dodanie nowego użytkownika w systemie
```bash
sudo adduser newsmbuser
```

2. Dodanie użytkownika do Samby:
```bash
sudo smbpasswd -a newsmbuser
```

3. Włączanie/Wyłączanie użytkowników Samba:
```bash
sudo smbpasswd -e newsmbuser # Włącza użytkownika
sudo smbpasswd -d newsmbuser # Wyłącza użytkownika
```

4. Zaktualizowanie konfiguracji Samby, by nowy użytkownik miał dostęp do zasobów:
```conf
[Shared]
    path = /srv/samba/shared
    valid users = adminuser, newsmbuser
    read only = no
    browsable = yes
```

### Zablokowanie dostępu do katalogu domowego użytkowników:

1. W pliku konfiguracyjnym Samby:
```bash
sudo nano /etc/samba/smb.conf
```
Uzupełniam/modyfikuję zmienne konfiguracyjne:

```conf
[homes]
   comment = Katalogi domowe użytkowników
   path = /home/%U
   browseable = no      # Zapewnia, że katalog domowy nie będzie widoczny w sieci
   read only = yes      # Zablokowanie dostępu do zapisu (można zmienić na "no", jeśli chcesz dać dostęp do zapisu)
   valid users = none   # Zablokowanie dostępu do katalogu domowego (żaden użytkownik nie ma dostępu)
```

### Restart Samby:

```bash
sudo systemctl restart smbd
```

### Testowanie:

- Windows: W Explorerze wpisuję \\<IP_SERWERA>\Shared i podaję dane logowania
- smbclient //IP_SERWERA/Shared -U adminuser

![Screenshot 3: SMB na Windows 10](/screenshots/fileserver/Przechwytywanie.webp)

### Security Note:

Samba działa na porcie 445 (SMB), który był wykorzystywany w atakach takich jak EternalBlue i WannaCry. Dlatego ważne jest ograniczenie dostępu do sieci LAN i wymuszenie użycia SMBv2/SMBv3.

### Porównanie protokołów:

| Protokół  | Szyfrowanie | Port | Obsługa Windows    | Zagrożenia            |
| --------- | ----------- | ---- | ------------------ | --------------------- |
| FTP       | ❌ Brak      | 21   | ✅ Wbudowany        | Sniffing, brute force |
| SFTP      | ✅ Tak (SSH) | 22   | ❌ Potrzebny klient | Brak widocznych haseł |
| SMB/Samba | ✅ (od v2+)  | 445  | ✅ Wbudowany        | EternalBlue, WannaCry |


---

## Podsumowanie

W tym rozdziale skonfigurowałem serwery plików zarówno do celów kompatybilnościowych (Samba/FTP), jak i nowoczesnych, bezpiecznych rozwiązań (SFTP). Porównanie ich bezpieczeństwa oraz analiza ruchu sieciowego (np. sniffing FTP haseł) stanowi wstęp do późniejszego rozdziału `fileserver-security.md`.

