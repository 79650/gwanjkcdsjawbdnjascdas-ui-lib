# qustah-ui-lib

Qustah'ın arayüzü, tek dosyalık bir Roblox UI kütüphanesi olarak. Pencere, dock, sayfalar, kartlar, toggle,
slider, dropdown, keybind, renk seçici, input, buton, bildirim ve config sistemi hazır gelir; scriptin
sadece özelliklerini yazarsın.

## Yükleme

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/dist/qustah-ui-lib.lua"))()
```

`USER` yerine GitHub kullanıcı adını yaz. Tam örnek: [`example.lua`](example.lua).

## Kısa örnek

```lua
local Window = Lib:CreateWindow({
    Title = "Qustāh", Version = "V1.00", Folder = "Qustah",
    ToggleKey = Enum.KeyCode.RightShift, Size = Vector2.new(560, 400),
})

local Visuals  = Window:Tab({ Title = "Visuals", Icon = "rbxassetid://78134819718605" })
local Overview = Visuals:Page("Overview")          -- 2+ sayfa olunca üstte sayfa şeridi çıkar
local General  = Overview:Card({ Title = "General" }) -- kartlar sırayla sol / sağ sütuna gider

General:Toggle({ Title = "ESP enabled", Flag = "esp", Default = true, Bindable = true,
    Callback = function(on) print(on) end })
General:Slider({ Title = "Max distance", Flag = "range", Min = 100, Max = 5000, Default = 1500, Step = 10, Suffix = "studs" })

Window:SettingsTab()          -- hazır Settings: tema rengi, menü tuşu, pencere, config kaydet / yükle
Window.Config:LoadAutoLoad()  -- autoload seçilmiş config'i yükler (UI kurulduktan sonra çağır)
```

## API

### Lib
| | |
|---|---|
| `Lib:CreateWindow(cfg)` | `Title, Version, Size (Vector2), MinSize, MaxSize, ToggleKey, Accent (Color3), Folder, Footer, KeyHints, CloseAction ("Hide" / "Destroy"), OnClose` — X menüyü gizler ve bildirim gösterir; `CloseAction = "Destroy"` tamamen kapatır |
| `Lib:Notify(cfg)` | `Title, Content, Duration (3), Color` |
| `Lib:SetAccent(color)` | Tema rengini değiştirir, bütün arayüz anında güncellenir |
| `Lib:SetColor(role, color)` | `base, card, input, line, text, muted, heading, accent ...` |
| `Lib.Flags` | `Flag` verilen her elemanın güncel değeri (`Lib.Flags.range`) |
| `Lib:Destroy()` | Bütün pencereleri ve bağlantıları kapatır |

### Window
| | |
|---|---|
| `Window:Tab({ Title, Icon, Divider })` | Dock'a sekme ekler (`Icon`: `rbxassetid://...` ya da sayı; `Divider = true` üstüne ayırıcı çizgi koyar) |
| `Window:KeyHint({ Title, Key, Side, Pressed, Callback, Flag })` | Alt bardaki tuş rozeti (`[NUM 8] • ESP / SILENT AIM`); rozete tıklayıp yeni tuş atanır. `MENU • RSHIFT` rozeti kendiliğinden gelir (`KeyHints = false` kapatır) |
| `Window:SettingsTab({ Title, Icon })` | Hazır ayarlar sekmesi |
| `Window:DashboardTab({ Title, Icon, Info = { { "Code revision", "571" } }, Server = true })` | Qustah'ın Dashboard'u: profil kartı (avatar, isim, oturum süresi), Session, Info (oyuncu sayısı, ping), Server (Rejoin, Server hop, Job ID). İlk sekme olarak çağır |
| `Window:Notify(cfg)` | `Lib:Notify` ile aynı |
| `Window:SetVisible(bool)`, `:Toggle()`, `:Minimize()` | Göster / gizle / başlığa katla |
| `Window:SetToggleKey(key)` | Menü tuşu (MENU rozeti ve Settings sekmesi de güncellenir) |
| `Window:SetStatus(text, color)`, `:SetFooter(text)` | Alt bar yazıları |
| `Window:SelectTab(tab or title)` | Sekme aç |
| `Window.Config` | `:Save(name)`, `:Load(name)`, `:Delete(name)`, `:List()`, `:SetAutoLoad(name)`, `:GetAutoLoad()`, `:LoadAutoLoad()` |
| `Window:Destroy()` | Pencereyi kapatır (`OnClose` çalışır) |

Aynı `Title` ile ikinci kez `CreateWindow` çağrılırsa eski pencere kapanır (script tekrar çalıştırılınca üst üste binmez).

### Tab / Page
| | |
|---|---|
| `Tab:Page(name, { Columns = 1 })` | Alt sayfa; `Columns = 1` tek sütun |
| `Tab:Card(cfg)` | Sayfa açmadan direkt kart (ilk sayfaya) |
| `Page:Card({ Title, Side = "Left" / "Right", Wide = true })` | Kart; `Side` yoksa sol / sağ sırayla; `Wide` iki sütunu kaplar, en üstte durur |
| `Page:Select()`, `Tab:Select()` | Aç |

Pencere daraldığında (< 470 px) iki sütun alt alta geçer; küçük ekranda pencere ölçeklenir.
Başlığın sağında açık sekme / sayfa yazar (`Visuals › Overview`).

### Elemanlar (`card:Eleman({ ... })`)
Hepsinde: `Title`, `Desc`, `Flag`, `Callback`, `Locked`, `LockedTitle`, `Help` (satırda küçük "i", tıklayınca açıklama).
Hepsi döner: `:Set(value)`, `:Get()`, `:OnChanged(fn)`, `:Lock(reason)`, `:Unlock()`, `:SetTitle(text)`, `:SetDesc(text)`, `:SetVisible(bool)`, `:Destroy()`.

| Eleman | Ek ayarlar | Değer |
|---|---|---|
| `Toggle` | `Default`, `Bindable`, `Bind` (KeyCode) — sağ tık ile tuş ata, Backspace siler | `boolean` (`:SetBind(key)`) |
| `Slider` | `Min, Max, Default, Step, Suffix` — değere tıklayıp yazılabilir | `number` (`:SetRange(min, max)`) |
| `Dropdown` | `Options, Default, Multi` | `string` / `{ string }` (`:SetOptions(list, keep)`) |
| `Keybind` | `Default`, `Pressed = function(key) end` | `Enum.KeyCode` / `nil` |
| `ColorPicker` | `Default` (Color3 ya da "RRGGBB") — kare, renk çubuğu, HEX, Random | `Color3` |
| `Input` | `Default, Placeholder, Numeric, ClearOnFocus, Finished = false` | `string` |
| `Button` | `Confirm = true` / `"metin"` (2 sn içinde ikinci tık ister) | `:Fire()` |
| `Label` | `"metin"` ya da `{ Title, Color }` | `:Set(text)` |
| `Paragraph` | `Title, Content` | `:SetContent(text)` |
| `Segment` | `Options, Default` — yan yana seçim butonları (Aim Part gibi), dar kartta başlığın altına geçer | `string` |
| `Info` | `Value, Copy = true / function` — salt okunur "ad ...... değer" satırı | `:Set(value)` |
| `Divider` | — | |

Kilit örneği:
```lua
local pred = Aim:Toggle({ Title = "Prediction", Locked = true, LockedTitle = "Önce Silent Aim'i aç" })
silent:OnChanged(function(on) if on then pred:Unlock() else pred:Lock("Önce Silent Aim'i aç") end end)
```

Config dosyaları `<Folder>/configs/<isim>.json`; autoload adı `<Folder>/autoload.txt`.


### v1.1 eklenenler

**Yeni elemanlar**

| Eleman | Örnek | Değer |
|---|---|---|
| `Range` | `card:Range({ Title, Flag, Min, Max, Default = { 20, 80 }, Step, MinGap })` | `{ alt, üst }` |
| `PlayerList` | `card:PlayerList({ Title, Flag, Multi = true, Height = 150 })` - arama, giren/çıkan canlı | UserId listesi, `:GetPlayers()` |
| `ImagePicker` | `card:ImagePicker({ Title, Flag, Images = { "rbxassetid://..." }, Columns = 4 })` | seçilen resim |
| `Swatches` | `card:Swatches({ Title, Flag, Colors = { { "Blue", Color3 } }, Default })` | renk adı, Callback(color, name) |
| `Graph` | `card:Graph({ Title, Source = "FPS" / "Ping" / function, Max })` | `:Push(sayi)` |

- `card:Tabs({ "Players", "Filters" })` -> kart içinde alt sekmeler (`sections.Players:Toggle{...}`).
- Toggle: `Marker = true` (sol accent çizgi), `Badge = "NEW"`.
- ColorPicker: içinde **Rainbow** butonu (`Rainbow = true`, `RainbowSpeed`), `Apply = true` -> sadece Apply'a basınca değişir.
- Keybind: `Chord = true, Default = { Enum.KeyCode.LeftControl, Enum.UserInputType.MouseButton1 }` (CTRL + M1).

**Pencere**

- `Window:Dialog({ Title, Content, Buttons = { { Title, Style = "Primary"/"Danger", Callback } } })`, `Window:Confirm(title, text, fn, buttonText, danger)` - Esc kapatır.
- `Window:KeybindList(true)`, `Window:SessionBar(true)`, `Window:StatsMonitor("Header"/"Floating"/"Off")` - Settings › Overlays'ten de açılır.
- Pencere konumu/boyutu ve paneller `Folder/window.json`'a kaydedilir, tekrar açınca aynı yerde.
- `Tab({ Header = true })` -> header'da yazı sekmesi (Dashboard / Settings varsayılan böyle).
- Sayfa kayarken üst/alt kenarda yumuşak geçiş.

**Durum / hatalar**

- `Window:SetModule("ESP", "On" | "Off" | "Limited" | "Error", detay)` -> Dashboard "Modules" + Settings › Info.
- Callback hataları UI'ı bozmaz; footer "Errors: N" olur. `Window:ReportError(src, msg)`, `GetErrorReport()`, `ClearErrors()`.
- `Window:SetStatus("yazı", renk)` elle; `SetStatus(nil)` otomatiğe döner (Connected / Limited / Errors).

**Settings**

- Interface: accent hazır renkler + özel renk, Text glow aç/kapa, menü tuşu, overlay'ler, Reset window, Unload (onaylı).
- Profiles: oluştur, Load / Overwrite / Rename / Duplicate / Delete / Autoload. Kilitli **Default** profili scriptin başlangıç değerleri. **SettingsTab'ı en son oluştur.**
- Info: versiyonlar, modüller, hata listesi, Copy report, Clear.

### v1.2 eklenenler

- **Tema paketleri:** Settings › Appearance › Theme: `Dark`, `Midnight`, `AMOLED`, `Light`. Kodla: `Lib.Theme.applyPack("Midnight")`. Accent rengin korunur; Neutral accent Light'ta koyulaşır.
- **Font:** Settings › Appearance › Font (Gotham, BuilderSans, Montserrat, Ubuntu, Roboto, SourceSans, Nunito, Arimo). Kalınlıklar korunur.
- **Bildirim geçmişi:** header'da zil ikonu. Yeni bildirim gelince nokta çıkar, tıklayınca son 50 bildirim açılır, Clear ile temizlenir. `Notify({ ..., History = false })` geçmişe yazmaz; `CreateWindow({ NotificationHistory = false })` zili kaldırır.
- **Watermark:** `Window:Watermark(true, { Text = "ekstra" })` -> "Qustāh  V1.00 | 60 FPS | 40 ms | 22:10", sürüklenebilir (Settings › Overlays).
- **Gradient:** `card:Gradient({ Title, Flag, Default = { Color3, Color3 }, Rotation, Callback = function(sequence, a, b) end })` - önizleme çubuğu, Start / End seçiciler, Swap. `:GetSequence()`.
- **Profiller (yenilendi):**
  - *Current*: aktif profil + kaydedilmemiş değişiklik sayısı; **Save**, **Revert**, **Share current**, **What changed?**
  - *New profile*: oluştur veya **paylaşım kodu** yapıştırıp **Import** (`QUSTAH1:...`, isim çakışırsa "pvp 2").
  - *Saved*: arama (3+ profilde), son kullanılan üstte, ACTIVE / AUTO / LOCKED etiketleri, profil **notu**, "N ayar farklı" özeti, Load (kaydedilmemiş değişiklik varsa sorar), Overwrite, Autoload, **Share**, Rename, Duplicate, Delete.
  - Kodla: `Config.Active`, `Config:Changes()`, `Config:Export(name)`, `Config:Decode(code)`, `Config:Read(name)`.

### v1.3: ikonlar

Icon alan her yerde artık **isim** yazabilirsin (asset id de çalışmaya devam eder):

```lua
Window:Tab({ Title = "Visuals", Icon = "eye" })                -- lucide (varsayılan, lib'in içinde, 1715 ikon)
Window:Tab({ Title = "Silent", Icon = "solar:target-bold" })   -- başka set: set:isim
Card({ Title = "Targets", Icon = "users" })                     -- kart başlığındaki nokta yerine
Toggle({ Title = "ESP", Icon = "scan-eye" })                    -- her elemanın başlığının soluna (Slider, Keybind, Dropdown...)
Button({ Title = "Rejoin", Icon = "refresh-cw" })
Lib:Notify({ Title = "Saved", Icon = "circle-check" })          -- bildirim + zil geçmişi
Lib:CreateWindow({ Title = "Qustāh", Icon = "swords" })         -- başlığın önünde logo
card:ImagePicker({ Images = { "crosshair", "solar:target-bold", "rbxassetid://..." } })
```

| Set | Ikon | Not |
|---|---|---|
| `lucide` | 1715 | lib'e gömülü, internet gerekmez |
| `solar` | 7330 | `-bold`, `-linear`, `-broken`, `-bold-duotone`... |
| `sfsymbols` | 6984 | `sfsymbols:HouseFill` (CamelCase) |
| `gravity` | 781 | |
| `geist` | 465 | spritesheet, iki tonlu ikonlar |
| `craft` | 998 | spritesheet |

lucide dışındaki setler ilk kullanımda bu repodaki `icons/` klasöründen bir kere indirilir.

```lua
Lib.Icons.SetDefault("solar")      -- önek yazmadan solar kullan (bulunamazsa lucide'e düşer)
Lib.Icons.Get("house")             -- { Image, RectSize, RectOffset, Parts }
Lib.Icons.Image("house", { Size = UDim2.fromOffset(24, 24), Color = Color3.new(1, 1, 1), Parent = frame })
Lib.Icons.Apply(myImageLabel, "solar:home-bold")
Lib.Icons.Add("mine", { skull = "rbxassetid://123" })   -- kendi setin -> "mine:skull"
Lib.Icons.List("lucide")           -- bütün isimler
```

İkon isimleri: [lucide.dev/icons](https://lucide.dev/icons), diğerleri için `icons/<set>.lua`. Ikonlar [Footagesus/Icons](https://github.com/Footagesus/Icons)'tan (MIT, `icons/LICENSE`).

## Geliştirme

```
src/            kaynak (modüller)
  init.lua        giriş: Lib API
  util.lua        yardımcılar (create, tween, maid, key / hex / pointer)
  theme.lua       renk rolleri + bağlama (SetAccent bütün objeleri günceller)
  window.lua      pencere, dock, sekmeler, sayfalar, sürükleme / boyutlandırma / katlama
  card.lua        kart + eleman kayıt listesi
  elements/       toggle, slider, dropdown, keybind, colorpicker, input, button, label, paragraph, divider, base
  notify.lua      bildirimler
  config.lua      config kaydet / yükle
  settings.lua    hazır Settings sekmesi
build.py        src/ -> dist/qustah-ui-lib.lua (tek dosya)
example.lua     bütün elemanlarla örnek
test/           mock testleri (run.sh) ve ekran görüntüleri (shot.sh)
```

Kaynağı düzenle, sonra `python3 build.py` çalıştır ve `dist/qustah-ui-lib.lua`'yı commit'le — raw link o dosyayı gösterir.
Yeni eleman: `src/elements/<ad>.lua` yaz (`return function(card, cfg) ... end`, `elements/base` ile), `card.lua` içindeki `Card.Elements` listesine ekle.
