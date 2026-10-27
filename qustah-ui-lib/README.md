<div align="center">

# Qustah UI Library

**Qustah'ın arayüzünü tek satırla scriptine getiren Roblox UI kütüphanesi.**

![version](https://img.shields.io/badge/version-1.6.0-8a8f98?style=flat-square)
![luau](https://img.shields.io/badge/Luau-executor-5b6ee1?style=flat-square)
![elements](https://img.shields.io/badge/elements-25-6aa86a?style=flat-square)
![themes](https://img.shields.io/badge/themes-20-c28b52?style=flat-square)
![icons](https://img.shields.io/badge/icons-18k%2B-b46fd1?style=flat-square)

</div>

Pencere, dock, sayfalar, kartlar, 25 eleman, bildirimler, profil sistemi, 20 tema ve 18.000+ ikon hazır gelir.
Sen sadece scriptin özelliklerini yazarsın; görünüm, kayıt, tema ve hata yönetimini kütüphane halleder.

- **Qustah görünümü:** sağda dock, iki sütunlu kartlar, alt bilgi çubuğu, tuş ipuçları, yumuşak animasyonlar
- **Profiller:** kaydet / yükle / autoload, paylaşım kodları, notlar, "ne değişti?", oyuna göre ayrı profiller, çökmeye dayanıklı kayıt
- **Temalar:** 20 hazır tema, kendi temanı yap ve kodla paylaş, her renk okunabilirlik testinden geçer
- **İkonlar:** lucide gömülü, solar / sfsymbols / gravity / geist / craft isteğe bağlı; her yerde isimle
- **Sağlam:** callback hataları arayüzü bozmaz, elemanda gösterilir ve listelenir; kick'ler sebebiyle kaydedilir
- **Hazır sekmeler:** Settings (tema, font, menü tuşu, overlay'ler, profiller, hata listesi) ve Dashboard

---

## İçindekiler

- [Kurulum](#kurulum)
- [Hızlı başlangıç](#hızlı-başlangıç)
- [Pencere](#pencere)
- [Sekmeler, sayfalar, kartlar](#sekmeler-sayfalar-kartlar)
- [Elemanlar](#elemanlar)
- [Flag'ler](#flagler)
- [Bildirimler](#bildirimler)
- [Diyaloglar](#diyaloglar)
- [Config ve profiller](#config-ve-profiller)
- [Hazır sekmeler](#hazır-sekmeler)
- [Overlay'ler](#overlayler)
- [Temalar](#temalar)
- [İkonlar](#ikonlar)
- [Durum, hatalar ve kick'ler](#durum-hatalar-ve-kickler)
- [Pencere ekstraları](#pencere-ekstraları)
- [Secure mode](#secure-mode)
- [Geliştirme](#geliştirme)

---

## Kurulum

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()
```

Küçültülmüş sürüm (aynı kod, yorumsuz, ~%25 daha küçük):

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.min.lua"))()
```

Her elemanın kullanıldığı tam örnek: [`example.lua`](example.lua)

## Hızlı başlangıç

```lua
local Window = Lib:CreateWindow({
    Title     = "Qustāh",
    Version   = "V1.00",
    Folder    = "Qustah",                  -- profiller Qustah/configs/ içine kaydedilir
    ToggleKey = Enum.KeyCode.RightShift,
})

local Visuals  = Window:Tab({ Title = "Visuals", Icon = "eye" })
local Overview = Visuals:Page("Overview")
local General  = Overview:Card({ Title = "General" })

General:Toggle({ Title = "ESP", Flag = "esp", Default = true, Callback = function(on) print("ESP", on) end })
General:Slider({ Title = "Max distance", Flag = "range", Min = 100, Max = 5000, Default = 1500, Step = 10, Suffix = "studs" })

Window:SettingsTab()          -- tema, font, menü tuşu, profiller... (en son oluştur)
Window.Config:LoadAutoLoad()  -- autoload seçilmiş profili yükler
```

Script tekrar çalıştırılınca aynı `Title`'lı eski pencere kendiliğinden kapanır, üst üste binmez.

---

## Pencere

```lua
local Window = Lib:CreateWindow({ Title = "Qustāh", Version = "V1.00", Folder = "Qustah" })
```

| Ayar | Varsayılan | Açıklama |
|---|---|---|
| `Title`, `Version` | `"Qustah UI"`, `""` | başlık ve yanındaki sürüm rozeti |
| `Icon` | — | başlığın önünde logo (ikon adı, asset id ya da web resmi) |
| `Tags` | — | başlığın yanında etiketler: `{ "BETA", { Text = "PRO", Color = Color3 } }` |
| `Folder` | başlık | dosyaların klasörü (profiller, pencere konumu, temalar) |
| `Size`, `MinSize`, `MaxSize` | `540×390` | `Vector2`; köşeden boyutlandırılır, küçük ekranda ölçeklenir |
| `ToggleKey` | `RightShift` | menüyü açıp kapatan tuş |
| `Accent` | Qustah grisi | `Color3` |
| `Footer` | oyunun adı | alt çubuğun ortasındaki yazı |
| `KeyHints` | `true` | alt çubuktaki `MENU • RSHIFT` rozeti |
| `CloseAction` | `"Hide"` | X: `"Hide"` gizler ve nasıl açılacağını söyler, `"Destroy"` tamamen kapatır |
| `SaveWindow` | `true` | konum, boyut ve paneller hatırlansın |
| `PerGame` | `false` | `"Game"` / `"Place"`: her oyunun kendi profilleri |
| `UnlockMouse` | `true` | menü açıkken mouse serbest (shift lock / first person) |
| `Profile`, `Anonymous` | `true`, `false` | dock'taki avatar butonu, anonim modda başla |
| `FullscreenButton` | `true` | header'daki tam ekran butonu |
| `NotificationHistory` | `true` | header'daki zil (bildirim geçmişi) |
| `Background`, `BackgroundTransparency` | — | arka plan resmi, pencere saydamlığı |
| `LiveBackground`, `AccentGlow` | `false` | arkada kayan accent ışığı, nefes alan kenar |
| `Welcome` | `true` | yeni hesap ilk açtığında "Signed in as" toast'ı |
| `AutoFlags` | `false` | Flag verilmeyen elemanlara isimden flag ([Flag'ler](#flagler)) |
| `Debug` | `false` | her yeni hata için bildirim |
| `KickLog`, `Rejoin`, `RejoinDelay` | `true`, `false`, `2` | kick kaydı, kick sonrası tekrar bağlan |
| `Secure` | `false` | [Secure mode](#secure-mode) |
| `OnClose` | — | pencere kapanınca çalışan fonksiyon |

| Metot | |
|---|---|
| `Window:Tab({ Title, Icon, Divider, Header })` | dock'a sekme ekler |
| `Window:SetVisible(bool)`, `:Toggle()`, `:Minimize()` | göster / gizle / başlığa katla |
| `Window:SetToggleKey(key)` | menü tuşunu değiştirir (rozet ve Settings de güncellenir) |
| `Window:SelectTab(tab or "Title")` | sekme açar |
| `Window:SetFooter(text)`, `:SetStatus(text, color)` | alt çubuk yazıları |
| `Window:Notify(cfg)`, `:Toast(cfg)` | bildirim, kısa hap bildirim |
| `Window:Destroy()` | her şeyi kapatır (`OnClose` çalışır) |

## Sekmeler, sayfalar, kartlar

```lua
local Visuals    = Window:Tab({ Title = "Visuals", Icon = "eye" })
local Overview   = Visuals:Page("Overview")                -- 2+ sayfa olunca üstte sayfa şeridi çıkar
local Appearance = Visuals:Page("Appearance", { Columns = 1 })

local Left  = Overview:Card({ Title = "General" })          -- kartlar sırayla sol / sağ sütuna gider
local Right = Overview:Card({ Title = "Colors", Side = "Right", Icon = "palette", Desc = "Kartın açıklaması" })
local Top   = Overview:Card({ Title = "Server", Wide = true })   -- iki sütunu kaplar, en üstte durur
```

- **Tab:** `Icon` dock'ta görünür; `Divider = true` üstüne ayırıcı çizgi koyar; `Header = true` header'da yazı sekmesi olarak da çıkar. `Tab:Card()` sayfa açmadan ilk sayfaya kart ekler.
- **Page:** `Columns = 1` tek sütun. Pencere 470 px'ten daralınca iki sütun alt alta geçer. `Warning = "..."` ya da `page:Warning("metin", { Title, Icon, Level = "warning" | "danger" | "info" })` sayfanın üstüne uyarı bandı koyar.
- **Card:** başlıktaki okla katlanır (`Collapsible = false` kaldırır, `Collapsed = true` kapalı başlar, durum hatırlanır). `card:SetCollapsed(bool)`, `card:SetTitle()`, `card:SetDesc()`, `card:SetVisible()`.

Kart içi düzen:

```lua
local tabs = Card:Tabs({ "Players", "Filters" })          -- başlıkta kapsül seçici, her biri ayrı bölüm
tabs.Players:Toggle({ Title = "Ignore friends" })

local advanced = Card:Section({ Title = "Advanced", Icon = "settings-2", Opened = false })  -- açılır bölüm
advanced:Slider({ Title = "Delay", Min = 0, Max = 1, Step = 0.05 })

local row = Card:Row()                                     -- içindekiler yan yana, eşit genişlikte
row:Button({ Title = "Start", Icon = "play" })
row:Button({ Title = "Stop", Icon = "square" })

local group = Card:Group({ Title = "Server" })             -- kutulu grup
group:Info({ Title = "Region", Value = "EU" })
```

---

## Elemanlar

Her eleman bir kartın (ya da Section / Row / Group / Tabs bölümünün) metodudur: `card:Toggle({ ... })`.

**Ortak ayarlar:** `Title`, `Desc`, `Flag`, `Callback`, `Icon` (başlığın soluna), `Help` (satırda "i", tıklayınca açıklama), `Risky` (kırmızı başlık, metin verilirse "i" ipucu olur), `Locked`, `LockedTitle`.

**Ortak metotlar:**

| Metot | |
|---|---|
| `:Set(value)`, `:Get()` | değer (Set callback'i de çalıştırır) |
| `:OnChanged(fn)` | ek dinleyici |
| `:Lock("sebep")`, `:Unlock()` | kilitler; sebep açıklamanın yerine yazılır (açıklama yoksa kilit ikonuyla kontrolün üstünde) |
| `:SetTitle(text)`, `:SetDesc(text)`, `:SetVisible(bool)` | |
| `:MoveUp()`, `:MoveDown()`, `:MoveTo(index)`, `:GetIndex()` | kart içindeki sırası |
| `:Flash("success" \| "danger" \| "accent")` | satırın arkasında kısa renk |
| `:Remove()` / `:Destroy()` | siler (flag kaydı da gider) |

Callback hata verirse eleman kırmızı yanıp söner ve başlığında 2 saniye "Error · see Settings › Info" yazar; hata Settings › Info'ya düşer, arayüz çalışmaya devam eder.

### Toggle

```lua
local esp = Card:Toggle({
    Title = "ESP", Desc = "Show player ESP", Flag = "esp", Default = true,
    Bindable = true,                          -- satıra sağ tık -> tuş ata (Backspace siler, Esc iptal)
    Bind = Enum.KeyCode.F,                    -- başlangıç tuşu
    BindMode = "Toggle",                      -- "Hold": sadece tuş basılıyken açık
    Marker = true, Badge = "NEW",             -- solda accent çizgi, başlığın yanında etiket
    Callback = function(on) end,
})
esp:SetBind(Enum.KeyCode.G)
```

### Slider ve Range

```lua
Card:Slider({
    Title = "FOV", Flag = "fov", Min = 10, Max = 600, Default = 120, Step = 1, Suffix = "px",
    Icons = { From = "minus", To = "plus" },  -- uçlarda ikon, tıklayınca bir adım
    Bubble = true,                            -- sürüklerken değer balonu
    Callback = function(value, dragging)      -- dragging: tutarken true, bırakınca son değerle false
        if not dragging then rebuildCircle(value) end
    end,
})
Card:Range({ Title = "Health filter", Flag = "hp", Min = 0, Max = 100, Default = { 20, 80 }, MinGap = 5 })  -- değer { alt, üst }
```

Değere tıklayıp sayı yazılabilir. `slider:SetRange(min, max)`.

### Dropdown ve Segment

```lua
Card:Dropdown({ Title = "Font", Flag = "font", Options = { "Gotham", "Code", "Arcade" }, Default = "Gotham" })

Card:Dropdown({ Title = "Show", Flag = "parts", Multi = true, Options = { "Name", "Health", "Distance" }, Default = { "Name" } })

Card:Dropdown({ Title = "Target", Flag = "priority", AllowNone = true, Options = {
    { Title = "Closest",   Icon = "footprints", Desc = "Nearest to you" },
    { Title = "Crosshair", Icon = "crosshair" },
    { Title = "Bounty",    Icon = "gem", Locked = true },
} })

Card:Dropdown({ Title = "Mode", Options = { pvp = "PvP mode", farm = "Auto farm" } })   -- değer anahtar ("pvp")

Card:Segment({ Title = "Aim part", Flag = "aimPart", Options = { "Head", "Body", "Closest" }, Default = "Head" })
```

- 8'den fazla seçenekte arama kutusu çıkar (`Search = true/false`); binlerce seçenek parça parça çizilir.
- Çoklu listede sürükleyerek seçilir (`DragSelect = false` kapatır).
- `:SetOptions(list, keepValue)`, `:GetLabel()`.

### Keybind

```lua
Card:Keybind({ Title = "Aim key", Flag = "aimKey", Default = Enum.KeyCode.Q, Pressed = function(key) end })

Card:Keybind({ Title = "Mark", Chord = true,               -- modifier + tuş / mouse (CTRL + M1)
    Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 } })

Card:Keybind({ Title = "Hold to aim", Default = Enum.KeyCode.E, Mode = "Hold",
    Pressed = function(down) aiming = down end })          -- basınca true, bırakınca false
```

Rozete tıkla, tuşa bas (Backspace siler, Esc iptal). `Callback` tuş değişince, `Pressed` tuşa her basışta çalışır.

### ColorPicker, Gradient, Swatches

```lua
Card:ColorPicker({ Title = "Fill", Flag = "fill", Default = Color3.fromRGB(215, 120, 120),
    Rainbow = false, RainbowSpeed = 5,       -- içinde Rainbow butonu da var
    Apply = false,                           -- true: sadece Apply'a basınca değişir
    Alpha = true, Transparency = 0.3,        -- saydamlık çubuğu
    Callback = function(color, transparency) end })

Card:Gradient({ Title = "Chams", Flag = "chams", Default = { Color3.new(1, 0, 0), Color3.new(0, 0, 1) },
    Callback = function(sequence, a, b) end })   -- :GetSequence()

Card:Swatches({ Title = "Name color", Flag = "nameColor", Default = "Blue",
    Callback = function(color, name) end })      -- Colors = { { "Blue", Color3 }, ... } verilmezse 8 hazır renk
```

Seçici: doygunluk karesi, renk çubuğu, HEX kutusu, Random, Rainbow. `"RRGGBB"` metni de kabul eder.

### Input ve ActionInput

```lua
Card:Input({ Title = "Target", Flag = "target", Placeholder = "player name", Numeric = false,
    Finished = true,                          -- false: her harfte callback
    Callback = function(text) end })

Card:ActionInput({ Icon = "plus", Placeholder = "Profile name", Button = "Create",
    Validate = function(text)                 -- canlı ipucu: ok = yeşil, false = kırmızı
        if text == "" then return nil end
        return #text <= 20, #text <= 20 and "Looks good" or "Too long"
    end,
    Callback = function(text) end })          -- butona ya da Enter'a basınca
```

### Button

```lua
Card:Button({ Title = "Rejoin", Icon = "refresh-cw", Callback = function() end })
Card:Button({ Title = "Server hop", Confirm = true, Callback = hop })        -- 2 sn içinde ikinci tık ister
Card:Button({ Title = "Delete all", Risky = true, Confirm = "Sure?", Callback = wipe })
```

### Metin: Label, Paragraph, Info, Divider, Code

```lua
Card:Label("Kısa açıklama satırı")
Card:Paragraph({ Title = "About", Content = "Uzun metin, satır satır kayar." })
Card:Info({ Title = "User ID", Value = "#123", Copy = true })   -- "ad ...... değer", Copy butonu
Card:Divider()
Card:Code({ Title = "loader.lua", Code = 'print("hi")', Copy = true, MaxHeight = 200 })   -- Lua renklendirme
```

### Canlı veri: Progress, Stat, Graph, Console

```lua
local farm  = Card:Progress({ Title = "Auto farm", Value = 3, Max = 10, Suffix = "quests" })
local daily = Card:Progress({ Title = "Daily quests", Steps = 5, Value = 2 })     -- 5 parçalı çubuk
local load  = Card:Progress({ Title = "Loading", Indeterminate = true })          -- kayan şerit
farm:Set(4)  load:SetIndeterminate(false)

local coins = Card:Stat({ Title = "Coins", Icon = "coins", Value = 12450, Prefix = "$" })
local ping  = Card:Stat({ Title = "Ping", Value = 48, Suffix = " ms", Delta = "absolute", Invert = true })
coins:Add(250)     -- rakamlar sayaç gibi döner, yanında "+2.0%" çipi

Card:Graph({ Title = "FPS", Source = "FPS", Max = 60 })     -- "Ping" ya da function() return n end

local log = Card:Console({ Title = "Log", Height = 140, MaxLines = 200 })
log:Append("Loaded", "success")        -- "info" | "success" | "warning" | "error"
log:Print("Sold", 3, "items")
```

- **Stat:** `Delta = "percent" | "absolute" | false`, `Invert = true` düşük değeri iyi sayar (yeşil), `Decimals`, `Separator`, `Format`.
- **Console:** yukarı kaydırınca takip durur, en alta inince devam eder. Başlıkta Takip / Temizle / Kopyala. `:Clear()`, `:GetText()`, `:SetFollow(bool)`.

### Görsel: Image, ImagePicker, PlayerList, Viewport

```lua
Card:Image({ Image = "rbxassetid://123", Height = 120, Caption = "Preview" })   -- ikon adı ya da web resmi de olur
Card:ImagePicker({ Title = "Crosshair", Flag = "cross", Columns = 4, Images = { "crosshair", "rbxassetid://9943168532" } })
Card:PlayerList({ Title = "Whitelist", Flag = "whitelist", Multi = true, Height = 150,
    Callback = function(userIds) end })          -- arama, giren / çıkan canlı; :GetPlayers()
Card:Viewport({ Object = game.Players.LocalPlayer.Character, Height = 150, Spin = true })   -- sürükle döndür, tekerlek zoom
```

---

## Flag'ler

`Flag` verilen her elemanın değeri profillere kaydedilir ve okunabilir:

```lua
print(Lib.Flags.esp)                -- bütün pencerelerin flag'leri
print(Window.Flags.esp)             -- aynı değer
Window.Flags.range = 2000           -- elemanı günceller ve callback'i çalıştırır
for flag, value in Window.Flags do print(flag, value) end

Window:SetFlag("esp", false)        -- eleman daha yoksa, oluşunca uygulanır
Window:GetElement("esp"):Lock("Premium only")
```

`CreateWindow({ AutoFlags = true })` ile Flag vermediğin değer elemanları `"Sekme.Kart.Başlık"` adında flag alır (aynı isim ikinciye `" 2"` eklenir). Settings ve Dashboard bundan etkilenmez.

---

## Bildirimler

```lua
Window:Notify({ Title = "Saved", Content = "pvp profile", Icon = "circle-check", Color = "success" })

Window:Notify({ Title = "Profile deleted", Buttons = {
    { Title = "Undo", Callback = undo },
    { Title = "Close" },
} })

local t = Window:Notify({ Title = "Farming", Steps = 5, Content = "Starting" })
t:SetStep(2, "Quest 2")             -- sona gelince kendi kapanır
```

| Ayar | |
|---|---|
| `Duration` | verilmezse yazı uzunluğuna göre 3–10 sn; üstüne gelince süre durur (`PauseOnHover = false`) |
| `Color` | `Color3` ya da rol: `"success"`, `"warning"`, `"danger"` |
| `Icon`, `Buttons`, `CanClose` | ikon, buton satırı, köşede X |
| `Progress`, `Steps`, `Step`, `Persist` | ilerlemeli bildirim (`:SetProgress`, `:SetStep`, `:Close`) |
| `Sound`, `Volume` | `true` (kısa ping) ya da ses id |
| `History` | `false`: zil geçmişine yazılmaz |

Ekranda en fazla `Lib.MaxNotifications` (6) bildirim durur, fazlası en eskiyi kapatır. Header'daki zil son 50 bildirimi tutar.

**Toast:** üstte ortada kısa hap.

```lua
Window:Toast("Copied")
Window:Toast({ Text = "Saved", Icon = "check", Color = "success", Position = "Bottom", Duration = 2 })
```

## Diyaloglar

```lua
Window:Dialog({ Title = "Enable Silent Aim?", Content = "Can be detected in ranked servers.", Icon = "triangle-alert", Buttons = {
    { Title = "Cancel" },
    { Title = "Enable", Style = "Danger", Callback = function() end },
} })

Window:Confirm("Unload?", "Everything will be removed.", function() Window:Destroy() end, "Unload", true)
```

Arka plan kararır ve kilitlenir; Esc ya da karanlık alana tıklamak iptal sayılır.

---

## Config ve profiller

Flag'li elemanlar `<Folder>/configs/<isim>.json`'a kaydedilir.

```lua
local Config = Window.Config
Config:Save("pvp")    Config:Load("pvp")    Config:Delete("pvp")
Config:List()         Config:Exists("pvp")  Config:Rename("pvp", "ranked")   Config:Copy("pvp", "pvp 2")
Config:SetAutoLoad("pvp")    Config:LoadAutoLoad()

Config.Active                       -- yüklü profil
Config:Changes()                    -- o profilden bu yana değişen ayar sayısı
Config:Export("pvp")                -- "QUSTAH1:..." paylaşım kodu
Config:Decode(code)                 -- isim, flag'ler

Config:SetData("waypoints", list)   -- kendi verin, profille kaydedilir / paylaşılır
Config:OnDataLoaded(function(data) end)
```

- `LoadAutoLoad` elemanlardan önce de çağrılabilir: değerler eleman oluşunca uygulanır.
- **Çökmeye dayanıklı:** her dosya önce `.tmp`'ye yazılıp kontrol edilir. Oyun kayıt sırasında kapanırsa profil bozulmaz, sonraki açılışta geri gelir (`Config:OnRecovered(fn)`).
- **Oyuna göre:** `CreateWindow({ PerGame = "Game" })` ya da Settings › Profiles: her oyunun kendi listesi ve autoload'u.

Settings › Profiles sayfası bunların hepsini arayüzle yapar: aktif profil ve değişiklik sayısı, Save / Revert, paylaşım kodu ile içe aktarma, arama, notlar, ACTIVE / AUTO / LOCKED etiketleri. Kilitli **Default** profili scriptin başlangıç değerleridir.

## Hazır sekmeler

```lua
Window:DashboardTab({ Info = { { "Code revision", "571" } }, Server = true })   -- ilk sekme olarak
-- ... kendi sekmelerin ...
Window:SettingsTab()                                                             -- son sekme olarak
```

- **Dashboard:** profil kartı (avatar, isim, oturum süresi), Session, Info, Modules, Server (Rejoin, Server hop, Job ID).
- **Settings › Interface:** tema, accent (hazır renkler + özel), font, text glow, tema editörü, menü tuşu, welcome toast, pencere (anonim mod, saydamlık, arka plan, serbest mouse, canlı arka plan, kenar parlaması, tam ekran), overlay'ler, Unload.
- **Settings › Profiles:** [Config ve profiller](#config-ve-profiller).
- **Settings › Info:** sürümler, secure mode durumu, kick listesi, modüller, hatalar (Debug mode, Copy report, Clear).

## Overlay'ler

Menü kapalıyken de ekranda kalırlar, sürüklenir ve yerleri hatırlanır. Hepsi Settings › Overlays'te de var.

```lua
Window:Watermark(true, { Text = "extra" })     -- "Qustāh  V1.00 | 60 FPS | 40 ms | 22:10"
Window:KeybindList(true)                       -- bağlı tuşlar; satıra tıkla = tuşa bas, göz ile satır gizle
Window:SessionBar(true)                        -- FPS · ping · oyuncu · süre
Window:StatsMonitor("Header" | "Floating" | "Off")

Window:KeyHint({ Title = "ESP / SILENT AIM", Key = Enum.KeyCode.KeypadEight, Side = "Left",
    Pressed = function() end })                -- alt çubukta tuş rozeti, tıklayınca yeni tuş
```

---

## Temalar

20 hazır tema: **Dark, Midnight, AMOLED, Light, Latte, Tokyo Night, Catppuccin, Dracula, Nord, Gruvbox, One Dark, Monokai, Rose Pine, Everforest, Kanagawa, Solarized, Oceanic, Fatality, Mint, Cyberpunk.**
Hepsi otomatik kontrast kontrolünden geçer (yazı 4.5:1, soluk yazı 3:1). Açık temalarda soluk accent renkleri okunacak kadar koyulaşır.

```lua
Lib.Theme.applyPack("Tokyo Night")
Lib:SetAccent(Color3.fromRGB(61, 151, 219))
Lib:SetColor("card", Color3.fromRGB(20, 20, 24))    -- base, card, input, line, text, muted, heading, accent, dock, icon...
```

Settings › Theme editor: renkleri tek tek değiştir, isim verip kaydet, `QTHEME1:` koduyla paylaş / içe aktar. Font: Gotham, BuilderSans, Montserrat, Ubuntu, Roboto, SourceSans, Nunito, Arimo.

## İkonlar

İkon alan her yere isim yazılır (asset id ve web resmi de olur):

```lua
Window:Tab({ Title = "Visuals", Icon = "eye" })               -- lucide (gömülü)
Window:Tab({ Title = "Silent", Icon = "solar:target-bold" })  -- set:isim
Card:Toggle({ Title = "ESP", Icon = "scan-eye" })
Lib:CreateWindow({ Title = "Qustāh", Icon = "https://example.com/logo.png" })
```

| Set | İkon | Not |
|---|---|---|
| `lucide` | 1715 | gömülü, internet gerekmez — [lucide.dev/icons](https://lucide.dev/icons) |
| `solar` | 7330 | `-bold`, `-linear`, `-broken`, `-bold-duotone`... |
| `sfsymbols` | 6984 | CamelCase: `sfsymbols:HouseFill` |
| `gravity` | 781 | |
| `geist` | 465 | iki tonlu |
| `craft` | 998 | |

lucide dışındaki setler ilk kullanımda bir kere indirilir.

```lua
Lib.Icons.SetDefault("solar")                            -- önek yazmadan solar
Lib.Icons.Image("house", { Size = UDim2.fromOffset(24, 24), Parent = frame })
Lib.Icons.Apply(imageLabel, "solar:home-bold")
Lib.Icons.Add("mine", { skull = "rbxassetid://123" })    -- "mine:skull"
Lib.Icons.List("lucide")
```

İkonlar [Footagesus/Icons](https://github.com/Footagesus/Icons)'tan (MIT, [`icons/LICENSE`](icons/LICENSE)).

---

## Durum, hatalar ve kick'ler

```lua
Window:SetModule("ESP", "On")                         -- "On" | "Off" | "Limited" | "Error", detay
Window:SetModule("Mark", "Limited", "client-side only")
Window:ReportError("ESP", "attempt to index nil")
Window:GetErrorReport()   Window:ClearErrors()
```

Modüller Dashboard'da ve Settings › Info'da görünür; alt çubuk kendiliğinden `Connected` / `Limited` / `Errors: N` olur.

**Kick yakalayıcı:** oyundan atılınca sebebi ve kodu yakalanır, son 20'si kaydedilir ve Settings › Info › Disconnects'te listelenir.

```lua
Window:OnKick(function(info)
    print(info.Kind, info.Reason, info.Code)   -- "Kicked", "Exploiting", 267
end)
Window:GetKicks()
-- CreateWindow({ Rejoin = true })  -> kick sonrası aynı yere ışınlanır
```

## Pencere ekstraları

```lua
Window:HeaderButton({ Icon = "refresh-cw", Tooltip = "Rejoin", Callback = rejoin })
Window:AddTag("NEW", { Color = "warning", Style = "Solid" | "Soft" })   -- yazı rengi dolguya göre seçilir

Window:ToggleFullscreen()                       -- header'a çift tık da yapar
Window:SetBackgroundImage("rbxassetid://123", 0.85)
Window:SetBackgroundTransparency(0.2)
Window:SetLiveBackground(true)                  -- arkada yavaşça kayan accent ışığı
Window:SetAccentGlow(true)                      -- kenar accent renginde nefes alır

Window:SetAnonymous(true)                       -- isim ve avatar her yerde gizlenir (dock'taki avatar butonu)
Window:SetMouseUnlock(false)
```

## Secure mode

```lua
getgenv().QUSTAH_SECURE = true                  -- lib'i yüklemeden önce
-- ya da CreateWindow({ Secure = true }) / Lib:SetSecure(true)
```

- ScreenGui isimleri rastgele GUID olur
- konsola hiçbir şey yazılmaz
- avatarlar web isteği olmadan (`rbxthumb://`) gelir

İkonlar asset id olarak kalır: Roblox asset indirmek için giriş istediğinden bunları dosyaya önbelleklemek bir proxy sunucusu gerektirir.

---

## Geliştirme

```
qustah-ui-lib/
  src/              kaynak kod (modüller)
    init.lua          giriş: Lib API
    window.lua        pencere, dock, sekmeler, sayfalar
    card.lua          kart + eleman listesi
    elements/         her eleman ayrı dosya, base.lua ortak satır / flaş / lock / sıra
    config.lua        profiller, güvenli kayıt
    theme.lua         renk rolleri, tema paketleri
    settings.lua      hazır Settings sekmesi
    ...
  dist/             tek dosya bundle (build.py üretir)
  icons/            indirilebilen ikon setleri
  test/             mock testleri ve ekran görüntüleri
  build.py          src/ -> dist/qustah-ui-lib.lua + .min.lua
  example.lua       her elemanın kullanıldığı örnek
```

Kaynağı düzenle, `python3 build.py` çalıştır, `dist/` ile birlikte commit'le — raw link o dosyayı gösterir.
Yeni eleman: `src/elements/<ad>.lua` yaz (`return function(card, cfg) ... end`, `elements/base` ile) ve `card.lua`'daki `Card.Elements` listesine ekle.
