# KozaOS — Proje Rehberi (Claude Code için)

Bu dosya, KozaOS reposunda çalışan Claude Code'un okuyacağı ana rehberdir. Her oturumun başında bunu oku ve kurallara uy.

## Proje nedir?

KozaOS, eski bilgisayarları yeniden kullanılabilir hâle getirmek için yapılan, **Arch Linux tabanlı** bir Linux dağıtımıdır.

- **Hedef kullanıcı:** Linux bilmeyen ev kullanıcısı (Türkiye öncelikli, ama İngilizce de desteklenir). Terminal açmadan her şeyi yapabilmeli.
- **Ana fikir:** "Eski bilgisayarına yeniden hayat ver." Koza → içinden yeni bir şey çıkar.
- **Kimlik:** Yazıda "KozaOS", her yerde teknik ad `kozaos` (GitHub org: `kozaos`).

## İki sürüm (flavor)

Aynı taban, aynı araçlar, iki farklı masaüstü. Her sürüm ayrı bir ISO olarak çıkar.

| | **KozaOS XFCE** | **KozaOS KDE** |
|---|---|---|
| Kimin için | Çok eski makineler (2008 sonrası 64-bit, eski ekran kartları) | Daha yeni eski makineler (2012 sonrası, Wayland'i kaldırabilen kartlar) |
| RAM | 2 GB'ta kullanılabilir, 4 GB'ta rahat | 4 GB ve üstü |
| Görüntü sunucusu | X11 | Sadece Wayland (Plasma 6.8 ve sonrasında X11 oturumu yok) |
| Giriş ekranı | LightDM (+ lightdm-gtk-greeter) | SDDM |
| ISO adı | `kozaos-xfce-YYYY.MM.DD-x86_64.iso` | `kozaos-kde-YYYY.MM.DD-x86_64.iso` |

Önce **XFCE** sürümü çıkar (projenin ana vaadi eski donanım), sonra KDE. Ama ortak kısımlar baştan iki sürüme de uyacak şekilde yazılır.

**Kural:** Bir şey iki sürümde de aynıysa `common` tarafına gider. Masaüstüne özel olan her şey kendi sürümünün klasöründe durur. Aynı ayarı iki yerde tekrar yazma.

## Değişmez kurallar

1. **Dürüst ol.** RAM, hız ve uyumluluk iddiaları gerçek ölçüme dayanmalı. Ölçülmemiş rakam README'ye ya da siteye yazılmaz.
2. **x86-64 baseline (v1) zorunlu.** Hedef makinelerden biri Core 2 Duo; SSE4.2 ve POPCNT yok. CachyOS'un v3/v4 repoları, `-march=native` ile derlenmiş paketler, x86-64-v2+ gerektiren hiçbir şey kullanılmaz. Sadece resmi Arch repoları ve kendi yerel repomuz.
3. **Bozulmaya karşı güvenlik ağı ilk günden var.** btrfs + snapper + grub-btrfs. Her paket güncellemesinden önce otomatik snapshot alınır, GRUB menüsünden önceki snapshot'a dönülebilir.
4. **Arch upstream'i değiştirme, üstüne ekle.** Ayarlarımız kendi paketlerimizde (`kozaos-*`) durur. Upstream paketleri yamalamaktan kaçın.
5. **Marka kopyalama yok.** Microsoft/Apple logosu, ismi ya da birebir tasarımı kullanılmaz.
6. **Her değişiklikten sonra etkilenen sürümlerin ISO'sunu QEMU'da boot edip doğrula** (aşağıdaki "Doğrulama" bölümü). "Çalışmalı" demek yetmez. Ortak bir şeyi değiştirdiysen iki sürümü de test et.

## Repo yapısı (hedef)

```
kozaos/
├── CLAUDE.md
├── README.md
├── archiso/
│   ├── common/                  # iki sürümün ortak profili (releng'den türetilmiş)
│   │   ├── profiledef.sh        # sürüm adı build sırasında yazılır
│   │   ├── packages.x86_64      # ortak paketler
│   │   ├── pacman.conf          # [kozaos] yerel reposu dahil
│   │   ├── airootfs/
│   │   ├── grub/  syslinux/  efiboot/
│   ├── xfce/
│   │   ├── packages.x86_64      # sadece XFCE'ye özel paketler
│   │   └── airootfs/            # XFCE'ye özel dosyalar (autologin vb.)
│   └── kde/
│       ├── packages.x86_64
│       └── airootfs/
├── packages/                    # kendi PKGBUILD'lerimiz
│   ├── kozaos-settings/         # ortak: zram, sysctl, I/O scheduler, servisler, locale
│   ├── kozaos-settings-xfce/    # XFCE varsayılanları (panel, tema, efektler)
│   ├── kozaos-settings-kde/     # KDE varsayılanları (Baloo kapalı, efektler, panel)
│   ├── kozaos-branding/         # ortak: logo, duvar kâğıtları, Plymouth, GRUB, os-release
│   ├── kozaos-branding-xfce/    # LightDM teması, XFCE/GTK teması
│   ├── kozaos-branding-kde/     # SDDM teması, Plasma look-and-feel paketi
│   ├── kozaos-snapshots/        # ortak: snapper + snap-pac + grub-btrfs
│   └── kozaos-calamares-config/ # ortak kurulum sihirbazı, sürüme göre küçük farklar
├── repo/                        # derlenmiş paketler (git'e girmez)
├── scripts/
│   ├── build-packages.sh        # packages/ → repo/
│   ├── build-iso.sh             # kullanım: build-iso.sh xfce|kde|all
│   │                            # common + seçilen sürümü geçici bir profilde birleştirip mkarchiso çalıştırır
│   └── run-vm.sh                # kullanım: run-vm.sh <iso> [--bios|--uefi] [--old-cpu] [--ram MB]
├── docs/
│   └── measurements.md          # her sürüm için ölçülen RAM ve açılış süreleri
└── out/                         # ISO çıktıları (git'e girmez)
```

`build-iso.sh` birleştirme kuralı: önce `common/` kopyalanır, sonra sürüm klasöründeki `airootfs/` üstüne yazılır, `packages.x86_64` dosyaları birleştirilir (tekrar eden satırlar silinir).

## Yol haritası

Sırayla ilerle. Bir aşama bitip doğrulanmadan sonrakine geçme. Her aşamada önce XFCE'yi bitir, sonra aynı aşamayı KDE için yap.

### Aşama 1 — Boot eden ISO (MVP)
- `archiso`'nun `releng` profilini `archiso/common/` olarak al, adını ve etiketlerini `kozaos` yap. Birleştirme yapan `build-iso.sh`'i yaz.
- **Ortak paketler:** Firefox (uBlock Origin ön yüklü, policies.json ile), NetworkManager, PipeWire, Mesa, `linux-firmware`, Türkçe fontlar ve `noto-fonts`.
- **XFCE paketleri:** `xfce4` grubu (`xfce4-goodies`'in tamamını değil, sadece gerekenleri: `xfce4-pulseaudio-plugin`, `xfce4-whiskermenu-plugin`, `xfce4-screenshooter`, `xfce4-taskmanager`, `ristretto`, `mousepad`, `thunar-archive-plugin`), `xarchiver`, `network-manager-applet`, `lightdm`, `lightdm-gtk-greeter`, `xorg-server`.
- **KDE paketleri:** `plasma-desktop`, `sddm`, `konsole`, `dolphin`, `kate`, `ark`, `spectacle`, `plasma-nm`, `plasma-pa`, `kscreen`, `breeze-gtk`, `powerdevil`, `bluedevil`. **`plasma-meta` / `kde-applications` kullanma.**
- Canlı ortam otomatik olarak masaüstüne giriş yapsın (canlı kullanıcı `koza`).
- Varsayılan dil Türkçe (`tr_TR.UTF-8`), klavye Türkçe Q; giriş ekranında dil/klavye değiştirilebilsin. İngilizce de tam çalışmalı.
- Sürücüler: modesetting; eski NVIDIA kartlar için **nouveau** (9600 GT gibi kartlara kapalı sürücü yok).
- **Bitti sayılır:** İki ISO da BIOS ve UEFI modunda QEMU'da masaüstüne açılıyor.

### Aşama 2 — Hafiflik
- **Ortak (`kozaos-settings`):**
  - `zram-generator`: RAM'in yarısı kadar zstd zram swap.
  - Döner diskte `bfq`, SSD'de `mq-deadline` (`udev` kuralıyla otomatik).
  - `vm.swappiness` zram'a uygun ayar.
  - Gereksiz servisler kapalı.
- **XFCE (`kozaos-settings-xfce`):** compositor varsayılan açık ama gölgeler/saydamlık kapalı; 2 GB altı RAM'de compositor tamamen kapanır. Thumbnail üretimi (tumbler) sınırlı.
- **KDE (`kozaos-settings-kde`):** Baloo kapalı, Akonadi yok, KDE Connect yok, animasyonlar kısa, blur kapalı.
- **Ölç** (4 GB'lık VM, masaüstü açıldıktan 1 dk sonra `free -m`) ve `docs/measurements.md`'ye yaz. Hedefler: **XFCE boşta 450 MB altı, KDE boşta 650 MB altı.** Hedef tutmazsa sebebini bul, rakamı süsleme.

### Aşama 3 — Kurulum sihirbazı
- Calamares (AUR'dan `PKGBUILD` alınıp `packages/` altında derlenir). Tek yapılandırma iki sürüme de hizmet eder; sadece giriş ekranı yöneticisi (LightDM/SDDM) ve kurulacak paket listesi farklıdır.
- Dosya sistemi varsayılan btrfs, alt birimler `@`, `@home`, `@cache`, `@log`.
- Sorular az ve sade: dil, saat dilimi (varsayılan İstanbul), klavye, disk (tüm diski sil / Windows'un yanına kur), kullanıcı adı ve şifre.
- Türkçe metinleri sade ve teknik terimsiz yaz ("diskin tamamını kullan" gibi).
- **Bitti sayılır:** İki sürüm de VM'de sıfır diske kuruluyor ve kurulu sistem açılıyor.

### Aşama 4 — Güvenlik ağı (snapshot)
- `kozaos-snapshots` (ortak): `snapper`, `snap-pac`, `grub-btrfs`.
- GRUB menüsünde "Önceki sürümlere dön" alt menüsü.
- Masaüstü bildirimi (iki sürümde de çalışan `notify-send` ile): "Bir şey bozulduysa yeniden başlatıp menüden dünkü sürümü seç."
- **Bitti sayılır:** VM'de bilerek bir paketi bozup snapshot'tan geri dönmek mümkün.

### Aşama 5 — Marka ve görünüm
- **Ortak:** logo (koza/kelebek motifi, ana renk sonradan belirlenecek), duvar kâğıtları, Plymouth, GRUB teması, `/etc/os-release` (`NAME="KozaOS"`, `ID=kozaos`, `ID_LIKE=arch`, `VARIANT="XFCE"` ya da `"KDE"`, `VARIANT_ID=xfce|kde`), fastfetch logosu.
- **İki sürümde de aynı düzen:** altta tek panel, solda başlat menüsü (XFCE'de Whisker Menu, KDE'de Kickoff), sağda saat ve sistem tepsisi. Kullanıcı bir sürümden ötekine geçtiğinde kaybolmamalı.
- Renkler ve ikonlar iki sürümde aynı olsun ki aynı dağıtım olduğu belli olsun.

### Aşama 6 — Güncelleme politikası (ortak)
- Kullanıcıya doğrudan Arch reposu değil, **gecikmeli snapshot** sunulur: Arch Linux Archive'den belirli bir tarihe sabitlenmiş mirror. Test ettikten sonra tarihi ileri alırız.
- Güncelleme arayüzü: KDE'de Discover; XFCE'de daha hafif bir araç (ör. `pamac` benzeri ya da kendi küçük güncelleyicimiz — karar vermeden önce sor). Flatpak + Flathub iki sürümde de etkin.

### Aşama 7 — Türkiye'ye özel (ortak, en son)
- e-Devlet / e-imza: kart okuyucu için `pcsclite`, `ccid`, `opensc` ve gerekli imzalama araçları; kurulumu tek tıkla yapan bir "Türkiye Paketi" uygulaması (GTK ya da Qt fark etmez, iki masaüstünde de çalışmalı).
- Banka ve kamu sitelerinin Firefox'ta çalışması için gerekli ayarlar.
- Bu aşamaya başlamadan önce Yiğit'e hangi sitelerin test edileceğini sor.

## Geliştirme ortamı

- **Derleme makineleri:** Proje iki makinede de geliştirilir, repo git ile senkron tutulur:
  - **ares** — CachyOS, i7, 16 GB RAM, SSD (ana makine)
  - **ruby** — EndeavourOS, i5-1155G7, 8 GB RAM, SSD (yedek; 8 GB RAM yüzünden derleme ile 4 GB'lık VM aynı anda çalıştırılmaz)
- **Makineden bağımsızlık kuralı — ÖNEMLİ:** Hangi makinede derlenirse derlensin çıkan ISO aynı olmalı. Makinenin kendi ayarları (`/etc/pacman.conf`, `/etc/makepkg.conf`, ek repolar) ISO'ya ya da paketlere **asla** sızmamalı. Bu özellikle CachyOS'ta kritik: oradaki repolar x86-64-v3/v4, `makepkg.conf` da `-march=x86-64-v3` bayraklı.
  - `mkarchiso` sadece `archiso/common/pacman.conf`'u kullanır; bu dosyada sadece resmi Arch repoları (`core`, `extra`, gerekirse `multilib`) ve `[kozaos]` olur.
  - `packages/` altındaki paketler makinenin `makepkg`'ıyla değil, **temiz chroot'ta** derlenir: `devtools` paketindeki `extra-x86_64-build` (ya da `mkarchroot` + `makechrootpkg`), Arch'ın standart `pacman.conf` ve `makepkg.conf`'u ile. `build-packages.sh` bunu yapar.
  - Script'ler makine adına, kullanıcı adına ya da sabit yollara bağlı olmaz; yollar repo köküne göre göreli yazılır.
  - Doğrulama: derlenen ikili paketlerde v2+ komut kullanılmadığını QEMU `-cpu core2duo` testi kanıtlar; bu test atlanmaz.
- Makine değiştirirken: `git pull`, ardından `./scripts/build-packages.sh` (yerel `repo/` git'te olmadığı için her makinede yeniden derlenir).
- Gerekli paketler (iki makinede de): `archiso`, `devtools`, `base-devel`, `qemu-desktop`, `edk2-ovmf`, `git`.
- ISO derlemek root ister: `sudo ./scripts/build-iso.sh xfce`. Script her seferinde eski `work/` klasörünü temizlemeli.

## Doğrulama

Her anlamlı değişiklikten sonra, etkilenen her sürüm için:
1. `./scripts/build-packages.sh` hatasız biter.
2. `sudo ./scripts/build-iso.sh <sürüm>` hatasız biter, ISO boyutunu raporla.
3. `run-vm.sh` ile **BIOS** ve **UEFI** modunda, 4 GB RAM ve 2 çekirdekle açılır.
4. Masaüstü geldiğinde `free -m` ve `systemd-analyze` çıktısını `docs/measurements.md`'ye kaydet.
5. `--old-cpu` (QEMU `-cpu core2duo`) ile bir kez çalıştır: "illegal instruction" hatası çıkmamalı.
6. **Sadece XFCE için:** `--ram 2048` ile de aç, masaüstü kullanılabilir olmalı.

Gerçek donanım testi (geliştirici yapar):
- **XFCE:** Core 2 Duo, 4 GB RAM, GeForce 9600 GT, 1 TB HDD olan masaüstü (sirius) ve 2007 model bir laptop.
- **KDE:** Bu makinelerde de denenir; Wayland açılmazsa bu beklenen bir sonuçtur, `docs/measurements.md`'ye "desteklenmiyor" diye not edilir.

## Çalışma tarzı

- Küçük adımlarla ilerle, her aşamanın sonunda commit at (açıklayıcı mesajla).
- Bir karar birden fazla şekilde yapılabiliyorsa ve sonradan değiştirmek zahmetliyse, önce sor.
- Geliştirici Türkçe konuşur; açıklamaları sade Türkçeyle yap, kod yorumları ve commit mesajları İngilizce olabilir.
