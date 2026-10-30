--!strict
-- Type definitions for qustah-ui-lib: autocomplete and type checks in editors with luau-lsp (VS Code "Luau Language
-- Server", Roblox Studio script editor...). Nothing here runs.
--
-- Use:
--   local Types = require(path.to.qustah)            -- this file, copied into your project
--   local Lib = loadstring(game:HttpGet(URL))() :: Types.Lib
--   local Window = Lib:CreateWindow({ Title = "Hub" }) -- Window, tabs, cards and elements are typed from here on

export type Role = string -- theme role: "accent", "success", "warning", "danger", "text", "muted", ...
export type Paint = Role | Color3
export type Callback<T...> = (T...) -> ()

-- DependsOn = "flag" | { Flag, Value, Not, Mode = "Lock" | "Hide", Reason } | function(flags) return bool end
export type Dependency = string | {
	Flag: string,
	Value: any?,
	Not: boolean?,
	Mode: ("Lock" | "Hide")?,
	Reason: string?,
} | (flags: { [string]: any }) -> boolean

-- options every element takes
export type ElementConfig = {
	Title: string?,
	Desc: string?,
	Flag: (string | false)?,
	Icon: string?,
	Help: string?,
	Tooltip: string?,
	Risky: (boolean | string)?,
	Locked: boolean?,
	LockedTitle: string?,
	DependsOn: Dependency?,
	Flash: boolean?,
	Reset: boolean?,
}

export type Element<T> = {
	Type: string,
	Title: string?,
	Flag: string?,
	Value: T,
	Locked: boolean,
	Set: (self: Element<T>, value: T, silent: boolean?) -> (),
	Get: (self: Element<T>) -> T,
	OnChanged: (self: Element<T>, callback: (value: T, ...any) -> ()) -> Element<T>,
	Lock: (self: Element<T>, reason: string?) -> (),
	Unlock: (self: Element<T>) -> (),
	SetTitle: (self: Element<T>, text: string) -> (),
	SetDesc: (self: Element<T>, text: string) -> (),
	SetVisible: (self: Element<T>, visible: boolean) -> (),
	SetTooltip: (self: Element<T>, text: string?) -> (),
	Flash: (self: Element<T>, kind: Paint?) -> (),
	MoveUp: (self: Element<T>) -> (),
	MoveDown: (self: Element<T>) -> (),
	MoveTo: (self: Element<T>, index: number) -> (),
	GetIndex: (self: Element<T>) -> number?,
	Remove: (self: Element<T>) -> (),
	Destroy: (self: Element<T>) -> (),
	ResetToDefault: (self: Element<T>) -> (),
}

export type Key = Enum.KeyCode | Enum.UserInputType

export type Toggle = Element<boolean> & {
	SetBind: (self: any, key: Key?) -> (),
	SetBindMode: (self: any, mode: "Toggle" | "Hold") -> (),
	BindKey: Key?,
}
export type Slider = Element<number> & { SetRange: (self: any, min: number, max: number) -> (), Dragging: boolean }
export type Dropdown = Element<any> & {
	SetOptions: (self: any, options: { any }, keepValue: boolean?) -> (),
	GetLabel: (self: any) -> string?,
}
export type Keybind = Element<any> & { Held: boolean, Mode: "Press" | "Hold" }
export type ColorPicker = Element<Color3> & {
	Transparency: number,
	SetTransparency: (self: any, value: number, silent: boolean?) -> (),
	SetRainbow: (self: any, on: boolean) -> (),
	SetOpen: (self: any, open: boolean) -> (),
}
export type Progress = Element<number> & {
	SetMax: (self: any, max: number) -> (),
	SetIndeterminate: (self: any, on: boolean) -> (),
	SetSteps: (self: any, count: number) -> (),
}
export type Stat = Element<number> & { Add: (self: any, amount: number) -> () }
export type Graph = Element<{ number }> & { Push: (self: any, value: number, series: string?) -> () }
export type Console = Element<string> & {
	Append: (self: any, text: any, level: ("info" | "success" | "warning" | "error" | "debug")?) -> any,
	Print: (self: any, ...any) -> any,
	Clear: (self: any) -> (),
	SetFollow: (self: any, on: boolean) -> (),
	GetText: (self: any) -> string,
}
export type Table = Element<{ { any } }> & {
	SetRows: (self: any, rows: { { any } }) -> (),
	AddRow: (self: any, row: { any }) -> number,
	RemoveRow: (self: any, index: number) -> (),
	UpdateRow: (self: any, index: number, row: { any }) -> (),
	Clear: (self: any) -> (),
	Sort: (self: any, column: number | string | nil, descending: boolean?) -> (),
	GetRows: (self: any) -> { { any } },
}
export type Radio = Element<any> & { SetOptions: (self: any, options: { any }) -> () }
export type PlayerList = Element<any> & { GetPlayers: (self: any) -> { Player } }
export type Info = Element<any> & { SetColor: (self: any, color: Paint?) -> () }

export type Container = {
	Toggle: (self: Container, cfg: ElementConfig & { Default: boolean?, Callback: Callback<boolean>?, Bindable: boolean?, Bind: Key?, BindMode: ("Toggle" | "Hold")?, Marker: boolean?, Badge: string? }) -> Toggle,
	Checkbox: (self: Container, cfg: ElementConfig & { Default: boolean?, Callback: Callback<boolean>? }) -> Element<boolean>,
	Slider: (self: Container, cfg: ElementConfig & { Min: number?, Max: number?, Default: number?, Step: number?, Suffix: string?, Callback: ((value: number, dragging: boolean?) -> ())?, Icons: { From: string?, To: string? }?, Bubble: boolean? }) -> Slider,
	Stepper: (self: Container, cfg: ElementConfig & { Min: number?, Max: number?, Step: number?, Default: number?, Suffix: string?, Callback: Callback<number>? }) -> Slider,
	TextArea: (self: Container, cfg: ElementConfig & { Placeholder: string?, Default: string?, Height: number?, MaxLength: number?, Finished: boolean?, Validate: ((text: string) -> (boolean?, string?))?, Callback: Callback<string>? }) -> Element<string> & { Valid: boolean? },
	Range: (self: Container, cfg: ElementConfig & { Min: number?, Max: number?, Default: { number }?, Step: number?, Suffix: string?, MinGap: number?, Callback: Callback<{ number }>? }) -> Element<{ number }>,
	Dropdown: (self: Container, cfg: ElementConfig & { Options: { any } | { [string]: string }, Default: any?, Multi: boolean?, AllowNone: boolean?, Search: boolean?, DragSelect: boolean?, Callback: Callback<any>? }) -> Dropdown,
	Segment: (self: Container, cfg: ElementConfig & { Options: { string }, Default: string?, Callback: Callback<string>? }) -> Element<string>,
	Radio: (self: Container, cfg: ElementConfig & { Options: { any }, Default: any?, Callback: Callback<any>? }) -> Radio,
	Keybind: (self: Container, cfg: ElementConfig & { Default: any?, Chord: boolean?, Mode: ("Press" | "Hold")?, Callback: Callback<any>?, Pressed: Callback<any>? }) -> Keybind,
	ColorPicker: (self: Container, cfg: ElementConfig & { Default: (Color3 | string)?, Apply: boolean?, Rainbow: boolean?, RainbowSpeed: number?, Alpha: boolean?, Transparency: number?, Callback: ((color: Color3, transparency: number?) -> ())? }) -> ColorPicker,
	Gradient: (self: Container, cfg: ElementConfig & { Default: { Color3 }?, Rotation: number?, Callback: ((sequence: ColorSequence, a: Color3, b: Color3) -> ())? }) -> Element<{ Color3 }>,
	Swatches: (self: Container, cfg: ElementConfig & { Colors: { any }?, Default: string?, Columns: number?, Callback: ((color: Color3, name: string) -> ())? }) -> Element<string>,
	Input: (self: Container, cfg: ElementConfig & { Default: string?, Placeholder: string?, Numeric: boolean?, ClearOnFocus: boolean?, Finished: boolean?, Callback: Callback<string>? }) -> Element<string>,
	ActionInput: (self: Container, cfg: ElementConfig & { Placeholder: string?, Button: string?, Hint: string?, Validate: ((text: string) -> (boolean?, string?))?, ClearOnAction: boolean?, Callback: Callback<string>? }) -> Element<string>,
	Button: (self: Container, cfg: ElementConfig & { Confirm: (boolean | string)?, Callback: Callback<>?,
		Style: ("Default" | "Primary" | "Soft" | "Outline" | "Ghost" | "Danger" | "Link")?, Size: ("Small" | "Default" | "Large")?,
		IconSide: ("Left" | "Right")?, Align: ("Center" | "Left")?, Cooldown: number?, Hold: number?, Loading: boolean?, LoadingText: string?, Done: boolean?,
		Bind: (Key | string)?, Bindable: boolean?, Toggle: boolean?, Default: boolean?, OnStyle: string?, OnTitle: string?, OnIcon: string?,
		Menu: { string | { Title: string, Icon: string? } }?, Selected: string?, ShowSelected: boolean?, Badge: (string | number)? }) -> Element<any> & {
		Fire: (self: any) -> (), SetStyle: (self: any, style: string) -> (), SetTitle: (self: any, text: string) -> (), SetIcon: (self: any, name: string) -> (),
		SetLoading: (self: any, on: boolean, text: string?) -> (), SetCooldown: (self: any, seconds: number) -> (), ResetCooldown: (self: any) -> (),
		SetBind: (self: any, key: (Key | string)?) -> (), SetBadge: (self: any, text: (string | number)?) -> (),
		Select: (self: any, option: string, silent: boolean?) -> (), SetOptions: (self: any, list: { any }) -> (),
		Style: string, Selected: string?, Loading: boolean?, CoolingDown: boolean? },
	Label: (self: Container, cfg: string | { Title: string?, Color: Paint? }) -> Element<string>,
	Paragraph: (self: Container, cfg: { Title: string?, Content: string? }) -> Element<string>,
	Info: (self: Container, cfg: { Title: string?, Value: any?, Copy: any? }) -> Info,
	Divider: (self: Container, cfg: {}?) -> any,
	Code: (self: Container, cfg: { Title: string?, Code: string?, Copy: boolean?, MaxHeight: number?, Highlight: boolean? }) -> Element<string>,
	Progress: (self: Container, cfg: ElementConfig & { Value: number?, Max: number?, Suffix: string?, Steps: number?, Indeterminate: boolean?, Format: ((value: number, max: number) -> string)? }) -> Progress,
	Stat: (self: Container, cfg: { Title: string?, Value: number?, Icon: string?, Prefix: string?, Suffix: string?, Decimals: number?, Separator: string?, Delta: ("percent" | "absolute" | false)?, Invert: boolean?, Format: ((value: number) -> string)? }) -> Stat,
	Graph: (self: Container, cfg: { Title: string?, Source: any?, Max: number?, Suffix: string?, Height: number?, Points: number?, Interval: number?, Style: ("Bars" | "Line")?, Compact: boolean?, Color: Paint?, Series: { { Name: string?, Source: any?, Color: Paint?, Suffix: string? } }? }) -> Graph,
	Console: (self: Container, cfg: { Title: string?, Height: number?, MaxLines: number?, Follow: boolean?, Time: boolean?, Copy: boolean? }) -> Console,
	Table: (self: Container, cfg: { Title: string?, Columns: { any }, Rows: { { any } }?, Height: number?, Search: boolean?, Sortable: boolean?, SortBy: any?, Descending: boolean?, OnRowClick: ((row: { any }, index: number) -> ())? }) -> Table,
	Image: (self: Container, cfg: { Image: string, Height: number?, Radius: number?, Fit: ("Crop" | "Fit")?, Caption: string? }) -> Element<string>,
	ImagePicker: (self: Container, cfg: ElementConfig & { Images: { string }, Default: string?, Columns: number?, Callback: Callback<string>? }) -> Element<string>,
	PlayerList: (self: Container, cfg: ElementConfig & { Multi: boolean?, Height: number?, IncludeSelf: boolean?, Callback: Callback<any>? }) -> PlayerList,
	Viewport: (self: Container, cfg: { Object: Instance?, Height: number?, Interactive: boolean?, Spin: boolean?, Distance: number? }) -> any,

	Tabs: (self: Container, names: { string }, cfg: { Default: string?, Callback: Callback<string>? }?) -> ({ [string]: Container }, any),
	Section: (self: Container, cfg: string | { Title: string?, Icon: string?, Desc: string?, Opened: boolean?, DependsOn: Dependency? }) -> Container & { SetOpen: (self: any, open: boolean) -> (), ToggleOpen: (self: any) -> () },
	Row: (self: Container, cfg: { Gap: number?, Widths: { number }? }?) -> Container,
	Presets: (self: Container, list: { any }, cfg: { Custom: boolean?, Callback: Callback<string>? }?) -> {
		Select: (self: any, name: string) -> (), Get: (self: any) -> string?, Add: (self: any, name: string, values: { [string]: any }) -> () },
	Group: (self: Container, cfg: string | { Title: string? }) -> Container,
}

export type Card = Container & {
	SetCollapsed: (self: Card, collapsed: boolean) -> (),
	SetTitle: (self: Card, text: string) -> (),
	SetDesc: (self: Card, text: string) -> (),
	SetVisible: (self: Card, visible: boolean) -> (),
	Collapsed: boolean?,
}

export type CardConfig = {
	Title: string?,
	Desc: string?,
	Icon: string?,
	Side: ("Left" | "Right")?,
	Wide: (boolean | "Bottom")?,
	Collapsible: boolean?,
	Dot: boolean?,
	Collapsed: boolean?,
	DependsOn: Dependency?,
	Empty: (string | false)?,
}

export type Page = {
	Name: string,
	Card: (self: Page, cfg: CardConfig?) -> Card,
	Warning: (self: Page, text: string, opts: { Title: string?, Icon: string?, Level: ("warning" | "danger" | "info")? }?) -> any,
	Select: (self: Page) -> (),
}

export type Tab = {
	Title: string,
	Pages: { Page },
	Build: (self: Tab) -> (),
	Page: (self: Tab, name: string, cfg: { Columns: number?, Warning: string? }?) -> Page,
	Card: (self: Tab, cfg: CardConfig?) -> Card,
	Select: (self: Tab) -> (),
	SetBadge: (self: Tab, value: (number | string | boolean)?, color: Paint?) -> (),
	SetActive: (self: Tab, on: boolean, color: Paint?) -> (),
}

export type NotifyConfig = {
	Title: string?,
	Content: string?,
	Duration: number?,
	Icon: string?,
	Color: Paint?,
	Buttons: { { Title: string, Callback: Callback<>?, Style: string?, Close: boolean? } }?,
	CanClose: boolean?,
	Progress: number?,
	Steps: number?,
	Step: number?,
	Persist: boolean?,
	Sound: (boolean | string | number)?,
	Volume: number?,
	History: boolean?,
	PauseOnHover: boolean?,
	Merge: boolean?,
}

export type Notification = {
	SetTitle: (self: any, text: string) -> (),
	SetContent: (self: any, text: string) -> (),
	SetProgress: (self: any, value: number) -> (),
	SetStep: (self: any, step: number, text: string?) -> (),
	Close: (self: any) -> (),
	IsOpen: (self: any) -> boolean,
}

export type Config = {
	Active: string?,
	Save: (self: Config, name: string) -> (boolean, string?),
	Load: (self: Config, name: string) -> (boolean, string?),
	Delete: (self: Config, name: string) -> (boolean, string?),
	List: (self: Config) -> { string },
	Exists: (self: Config, name: string) -> boolean,
	Rename: (self: Config, old: string, new: string) -> (boolean, string?),
	Copy: (self: Config, name: string, new: string) -> (boolean, string?),
	SetAutoLoad: (self: Config, name: string) -> boolean,
	GetAutoLoad: (self: Config) -> string?,
	LoadAutoLoad: (self: Config) -> (boolean, string?),
	Changes: (self: Config, flags: { [string]: any }?) -> (number, { string }),
	Export: (self: Config, name: string?) -> (string?, string?),
	Decode: (self: Config, code: string) -> (string?, any, any),
	SetData: (self: Config, key: string, value: any) -> (),
	GetData: (self: Config, key: string) -> any,
	OnDataLoaded: (self: Config, callback: (data: { [string]: any }) -> ()) -> (),
	OnRecovered: (self: Config, callback: (name: string) -> ()) -> (),
	SetPerGame: (self: Config, mode: ("Game" | "Place" | false)?) -> (),
}

export type KickInfo = { Reason: string, Code: number?, Kind: string, Message: string, Time: number }

export type Window = {
	Title: string,
	Version: string,
	Config: Config,
	Flags: { [string]: any },
	Tab: (self: Window, cfg: string | { Title: string, Icon: string?, Divider: boolean?, Header: boolean?, Build: ((tab: Tab) -> ())?, BuildDelay: (number | false)? }) -> Tab,
	BuildAll: (self: Window) -> (),
	SetUIScale: (self: Window, scale: number) -> (),
	GetUIScale: (self: Window) -> number,
	SetMobileButton: (self: Window, on: boolean, remember: boolean?) -> (),
	SettingsTab: (self: Window, cfg: { Title: string?, Icon: string?, Info: { { string } }? }?) -> Tab,
	DashboardTab: (self: Window, cfg: { Title: string?, Icon: string?, Info: { { string } }?, Server: boolean? }?) -> Tab,
	Notify: (self: Window, cfg: NotifyConfig | string) -> Notification,
	Toast: (self: Window, cfg: string | { Text: string, Icon: string?, Image: string?, Color: Paint?, Position: ("Top" | "Bottom")?, Duration: number? }) -> any,
	Dialog: (self: Window, cfg: { Title: string?, Content: string?, Icon: string?, Buttons: { { Title: string, Style: ("Primary" | "Danger")?, Callback: Callback<>? } }?, OnCancel: Callback<>? }) -> any,
	Confirm: (self: Window, title: string, content: string?, onConfirm: Callback<>, confirmText: string?, danger: boolean?) -> any,
	SetVisible: (self: Window, visible: boolean) -> (),
	Toggle: (self: Window) -> (),
	Minimize: (self: Window) -> (),
	SelectTab: (self: Window, tab: Tab | string) -> Tab?,
	SetToggleKey: (self: Window, key: Key) -> (),
	SetFooter: (self: Window, text: string) -> (),
	SetStatus: (self: Window, text: string?, color: Paint?) -> (),
	SetFlag: (self: Window, flag: string, value: any) -> boolean,
	GetFlag: (self: Window, flag: string) -> any,
	GetElement: (self: Window, flag: string) -> Element<any>?,
	KeyHint: (self: Window, cfg: { Title: string?, Key: Key?, Side: ("Left" | "Right")?, Pressed: Callback<any>?, Callback: Callback<any>?, Flag: string? }) -> any,
	HeaderButton: (self: Window, cfg: { Icon: string?, Tooltip: string?, Callback: Callback<>? }) -> any,
	AddTag: (self: Window, text: string, opts: { Color: Paint?, Style: ("Solid" | "Soft")? }?) -> any,
	SetModule: (self: Window, name: string, state: "On" | "Off" | "Limited" | "Error", detail: string?, meta: { Icon: string?, Tab: string? }?) -> (),
	ReportError: (self: Window, source: string, message: string) -> (),
	OnKick: (self: Window, callback: (info: KickInfo) -> ()) -> (),
	GetKicks: (self: Window) -> { any },
	Watermark: (self: Window, visible: boolean, cfg: { Text: string? }?) -> (),
	KeybindList: (self: Window, visible: boolean) -> (),
	SessionBar: (self: Window, visible: boolean) -> (),
	StatsMonitor: (self: Window, mode: "Header" | "Floating" | "Off") -> (),
	SetFullscreen: (self: Window, on: boolean) -> (),
	ToggleFullscreen: (self: Window) -> (),
	SetBackgroundImage: (self: Window, image: string?, transparency: number?) -> (),
	SetBackgroundTransparency: (self: Window, value: number) -> (),
	SetLiveBackground: (self: Window, on: boolean) -> (),
	SetAccentGlow: (self: Window, on: boolean) -> (),
	SetBlur: (self: Window, on: boolean, size: number?) -> (),
	SetAnonymous: (self: Window, on: boolean) -> (),
	SetMouseUnlock: (self: Window, on: boolean) -> (),
	ShowChangelog: (self: Window) -> any,
	Tour: (self: Window, steps: { { Target: any?, Title: string?, Text: string?, OnShow: (() -> ())? } }?, opts: { Id: string?, Once: boolean?, Force: boolean?, OnFinish: ((completed: boolean) -> ())? }?) -> any,
	HasSeenTour: (self: Window, id: string?) -> boolean,
	ResetTour: (self: Window, id: string?) -> (),
	GetKeyConflicts: (self: Window) -> { [string]: { string } },
	Destroy: (self: Window) -> (),
}

export type WindowConfig = {
	Title: string?,
	Version: string?,
	Icon: string?,
	Tags: { any }?,
	Folder: string?,
	Size: Vector2?,
	MinSize: Vector2?,
	MaxSize: Vector2?,
	ToggleKey: Key?,
	Accent: Color3?,
	Footer: string?,
	KeyHints: boolean?,
	CloseAction: ("Hide" | "Destroy")?,
	SaveWindow: boolean?,
	PerGame: ("Game" | "Place" | boolean)?,
	UnlockMouse: boolean?,
	Profile: boolean?,
	Anonymous: boolean?,
	FullscreenButton: boolean?,
	NotificationHistory: boolean?,
	Background: string?,
	BackgroundTransparency: number?,
	LiveBackground: boolean?,
	AccentGlow: boolean?,
	Blur: boolean?,
	BlurSize: number?,
	Sounds: boolean?,
	Scale: number?,
	MobileButton: (boolean | "Auto")?,
	MobileIcon: string?,
	Welcome: boolean?,
	AutoFlags: boolean?,
	ResetButtons: boolean?,
	Debug: boolean?,
	KickLog: boolean?,
	Rejoin: boolean?,
	RejoinDelay: number?,
	Secure: boolean?,
	Tour: (boolean | { any })?,
	TourDelay: number?,
	CardDots: boolean?,
	TourId: string?,
	Changelog: { Version: string?, Title: string?, Content: string?, Items: { string }?, Button: string?, Delay: number? }?,
	KeySystem: {
		Keys: { string }?,
		Check: ((key: string) -> (boolean, string?))?,
		Url: string?,
		Title: string?,
		Subtitle: string?,
		Note: string?,
		Icon: string?,
		Remember: boolean?,
		OnCancel: Callback<>?,
	}?,
	OnClose: Callback<>?,
}

export type Lib = {
	Version: string,
	Flags: { [string]: any },
	Windows: { Window },
	MaxNotifications: number,
	Theme: any,
	Icons: any,
	Haptics: { Enabled: boolean, Play: (kind: ("click" | "notify")?) -> () },
	Sounds: { Enabled: boolean, Volume: number, Play: (name: string) -> (), Set: (name: string, id: string | number, speed: number?, volume: number?) -> () },
	CreateWindow: (self: Lib, cfg: WindowConfig?) -> Window,
	Notify: (self: Lib, cfg: NotifyConfig | string) -> Notification,
	Toast: (self: Lib, cfg: any) -> any,
	SetAccent: (self: Lib, color: Color3) -> (),
	SetColor: (self: Lib, role: string, color: Color3) -> (),
	GetFlag: (self: Lib, flag: string) -> any,
	SetSecure: (self: Lib, on: boolean?) -> (),
	IsSecure: (self: Lib) -> boolean,
	ForgetKey: (self: Lib, folder: string?) -> (),
	Destroy: (self: Lib) -> (),
}

return nil
