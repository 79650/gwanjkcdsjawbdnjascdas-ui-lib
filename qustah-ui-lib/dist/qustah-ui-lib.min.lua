-- qustah-ui-lib v1.9.2 (minified build of dist/qustah-ui-lib.lua)
local __modules,__loaded={},{}
local function require(name)
local loaded=__loaded[name]
if loaded==nil then
local module=__modules[name]
if not module then error("[qustah-ui-lib] missing module: "..tostring(name),2)end
loaded=module()
__loaded[name]=loaded
end
return loaded
end
__modules["card"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local Card={}
Card.Elements={
Toggle=require("elements/toggle"),
Slider=require("elements/slider"),
Dropdown=require("elements/dropdown"),
Keybind=require("elements/keybind"),
ColorPicker=require("elements/colorpicker"),
Input=require("elements/input"),
Button=require("elements/button"),
Label=require("elements/label"),
Paragraph=require("elements/paragraph"),
Divider=require("elements/divider"),
Segment=require("elements/segment"),
Info=require("elements/info"),
Range=require("elements/range"),
PlayerList=require("elements/playerlist"),
ImagePicker=require("elements/imagepicker"),
Swatches=require("elements/swatches"),
Graph=require("elements/graph"),
Gradient=require("elements/gradient"),
Progress=require("elements/progress"),
Code=require("elements/code"),
Image=require("elements/image"),
Viewport=require("elements/viewport"),
ActionInput=require("elements/actioninput"),
Stat=require("elements/stat"),
Console=require("elements/console"),
Checkbox=require("elements/checkbox"),
Radio=require("elements/radio"),
Table=require("elements/table"),
Stepper=require("elements/stepper"),
TextArea=require("elements/textarea"),
}
Card.__index=function(_,key)
local method=rawget(Card,key)
if method~=nil then return method end
local constructor=Card.Elements[key]
if constructor then
return function(self,cfg)
if type(cfg)=="string"then cfg={Title=cfg}end
return constructor(self,cfg or{})
end
end
return nil
end
function Card.new(page,column,cfg,order)
local self=setmetatable({page=page,window=page.window,order=0,title=cfg.Title},Card)
local frame=create("Frame",{
Name=cfg.Title or"Card",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
BorderSizePixel=0,LayoutOrder=order or 0,Parent=column,
})
Theme.bind(frame,"BackgroundColor3","card")
corner(frame,8)
Theme.bind(stroke(frame),"Color","line")
Util.padding(frame,14,14,8,10)
Util.list(frame,4)
if cfg.Title then
local head=create("Frame",{Name="Heading",BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=0,Parent=frame})
local icon=cfg.Icon and Icons.themed(head,cfg.Icon,13,"accent",{Name="CardIcon",Position=UDim2.fromOffset(-1,3)})
for ring=3,(icon and 4 or 0),-1 do
local dot=create("Frame",{
Name=ring==0 and"Dot"or"Glow",Position=UDim2.fromOffset(-ring,7-ring),Size=UDim2.fromOffset(6+ring*2,6+ring*2),
BorderSizePixel=0,BackgroundTransparency=ring==0 and 0 or 0.91,Parent=head,
})
Theme.bind(dot,"BackgroundColor3","accent")
corner(dot,ring==0 and 3 or 6)
end
local collapsible=cfg.Collapsible~=false
local title=label(head,tostring(cfg.Title),10,{Position=UDim2.fromOffset(icon and 18 or 13,0),Size=UDim2.new(1,(icon and-18 or-13)-(collapsible and 22 or 0),1,0),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3","heading")
self.titleLabel=title
if cfg.Desc then
local desc=label(frame,tostring(cfg.Desc),9,{Name="CardDesc",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,TextTruncate=Enum.TextTruncate.None,LayoutOrder=1})
Theme.bind(desc,"TextColor3","muted")
self.descLabel=desc
end
if collapsible then
local arrow=create("TextButton",{Name="Collapse",Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,4,0,0),Size=UDim2.fromOffset(20,20),Parent=head})
local chevron=create("Frame",{Name="Chevron",BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(10,10),Parent=arrow})
local bars={}
for index,rotation in ipairs({45,-45})do
local bar=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(index==1 and 3 or 7,5),Size=UDim2.fromOffset(6,1.5),Rotation=rotation,BorderSizePixel=0,Parent=chevron})
Theme.bind(bar,"BackgroundColor3","muted")
bars[#bars+1]=bar
end
arrow.MouseEnter:Connect(function()for _,bar in ipairs(bars)do Theme.tweenTo(bar,"BackgroundColor3","heading",0.1)end end)
arrow.MouseLeave:Connect(function()for _,bar in ipairs(bars)do Theme.tweenTo(bar,"BackgroundColor3","muted",0.1)end end)
self._chevron=chevron
arrow.Activated:Connect(function()self:SetCollapsed(not self.Collapsed)end)
end
self._key=tostring(page.tab and page.tab.Title or"").."/"..tostring(page.Name or"").."/"..tostring(cfg.Title)
end
self.frame,self.body=frame,frame
if cfg.Empty~=false then
local empty=label(frame,tostring(cfg.Empty or"Nothing here"),10,{
Name="Empty",Size=UDim2.new(1,0,0,30),TextXAlignment=Enum.TextXAlignment.Center,Visible=false,LayoutOrder=1,
})
Theme.bind(empty,"TextColor3","muted")
local queued=false
local function check()
queued=false
if not frame.Parent then return end
local any=false
for _,child in ipairs(frame:GetChildren())do
if child:IsA("GuiObject")and child~=empty and child.Name~="Heading"and child.Name~="CardDesc"and(child.Visible or(self._hidden and self._hidden[child]))then
any=true
break
end
end
empty.Visible=not any and not self.Collapsed
end
local function queue()
if queued then return end
queued=true
task.defer(check)
end
frame.ChildAdded:Connect(function(child)
if child:IsA("GuiObject")and child~=empty then child:GetPropertyChangedSignal("Visible"):Connect(queue)end
queue()
end)
frame.ChildRemoved:Connect(queue)
self._checkEmpty=queue
queue()
end
if cfg.DependsOn then require("elements/base").depend(self.window,cfg.DependsOn,function(ok)frame.Visible=ok return frame.Parent~=nil end)end
local memory=self.window.memory and self.window.memory.collapsed
if self._chevron and((memory and memory[self._key])or cfg.Collapsed)then
task.defer(function()self:SetCollapsed(true,true)end)
end
return self
end
function Card:SetCollapsed(collapsed,quiet)
collapsed=collapsed==true
if collapsed==(self.Collapsed==true)then return end
self.Collapsed=collapsed
self._hidden=self._hidden or{}
for _,child in ipairs(self.frame:GetChildren())do
if child:IsA("GuiObject")and child.Name~="Heading"and child.Name~="CardDesc"and child.Name~="Empty"then
if collapsed then
if child.Visible then self._hidden[child]=true child.Visible=false end
elseif self._hidden[child]then
child.Visible=true
end
end
end
if not collapsed then self._hidden={}end
if self._checkEmpty then self._checkEmpty()end
if self._chevron then Util.tween(self._chevron,0.15,{Rotation=collapsed and-90 or 0})end
local window=self.window
if self._key and window.memory and not quiet then
window.memory.collapsed=window.memory.collapsed or{}
window.memory.collapsed[self._key]=collapsed or nil
window:_saveMemory()
end
end
function Card:SetDesc(text)if self.descLabel then self.descLabel.Text=tostring(text)end end
function Card:_order()
self.order=self.order+2
return self.order
end
function Card:Tabs(names,cfg)
cfg=cfg or{}
local holder
if self.titleLabel then
holder=create("Frame",{Name="Tabs",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,self._chevron and-20 or 0,0,1),Size=UDim2.new(0.6,self._chevron and-20 or 0,0,18),Parent=self.titleLabel.Parent})
self.titleLabel.Size=UDim2.new(0.4,-13,1,0)
else
holder=create("Frame",{Name="Tabs",BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=self:_order(),Parent=self.body})
end
local layout=Util.list(holder,4,Enum.FillDirection.Horizontal)
layout.HorizontalAlignment=Enum.HorizontalAlignment.Right
local self_card=self
local sections,buttons,current={},{},nil
local selector={}
local function render()
for name,button in pairs(buttons)do
local on=name==current
Theme.tweenTo(button,"BackgroundColor3",on and"selected"or"input",0.1)
Theme.tweenTo(button,"TextColor3",on and"heading"or"muted",0.1)
sections[name].body.Visible=on
end
end
function selector:Select(name)
if not sections[name]then return end
current=name
render()
if cfg.Callback then self_card.window:_safe("Tabs",cfg.Callback,name)end
end
function selector:Get()return current end
for index,name in ipairs(names)do
name=tostring(name)
local button=create("TextButton",{
Name=name,AutoButtonColor=false,BorderSizePixel=0,Text=name,TextSize=9,Font=Enum.Font.GothamMedium,
Size=UDim2.fromOffset(Util.textWidth(name,9,Enum.Font.GothamMedium)+16,18),LayoutOrder=index,Parent=holder,
})
corner(button,9)
buttons[name]=button
local body=create("Frame",{Name="Section_"..name,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=self:_order(),Visible=false,Parent=self.body})
Util.list(body,4)
sections[name]=setmetatable({page=self.page,window=self.window,order=0,body=body,frame=self.frame,title=self.title},Card)
button.Activated:Connect(function()selector:Select(name)end)
end
current=tostring(cfg.Default or names[1])
render()
return sections,selector
end
local function same(a,b)
if type(a)=="number"and type(b)=="number"then return math.abs(a-b)<1e-6 end
if type(a)~="table"or type(b)~="table"then return a==b end
for key,value in pairs(a)do if not same(value,b[key])then return false end end
for key in pairs(b)do if a[key]==nil then return false end end
return true
end
function Card:Presets(list,cfg)
cfg=cfg or{}
local window=self.window
local presets={}
if type(list)=="table"and list[1]~=nil then
for _,entry in ipairs(list)do
local name=entry.Name or entry[1]
local values=entry.Values or entry[2]
if name~=nil and type(values)=="table"then presets[#presets+1]={name=tostring(name),values=values}end
end
elseif type(list)=="table"then
for name,values in pairs(list)do
if type(values)=="table"then presets[#presets+1]={name=tostring(name),values=values}end
end
table.sort(presets,function(a,b)return a.name<b.name end)
end
local holder
local inHeader=self.titleLabel and not self.titleLabel.Parent:FindFirstChild("Tabs")and not self.titleLabel.Parent:FindFirstChild("Presets")
if inHeader then
holder=create("Frame",{Name="Presets",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,self._chevron and-20 or 0,0,1),Size=UDim2.new(0.65,self._chevron and-20 or 0,0,18),Parent=self.titleLabel.Parent})
self.titleLabel.Size=UDim2.new(0.35,-13,1,0)
else
holder=create("Frame",{Name="Presets",BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=self:_order(),Parent=self.body})
end
local layout=Util.list(holder,4,Enum.FillDirection.Horizontal)
layout.HorizontalAlignment=inHeader and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
local chips={}
local selector={Presets=presets}
local current,applying,custom=nil,false,nil
local showCustom=cfg.Custom~=false
local function flags(values)
local out={}
for flag in pairs(values)do out[#out+1]=flag end
return out
end
local function match()
for _,preset in ipairs(presets)do
local all=true
for flag,value in pairs(preset.values)do
if not same(window.Lib.Flags[flag],value)then all=false break end
end
if all then return preset.name end
end
return"Custom"
end
local function render()
for name,chip in pairs(chips)do
local on=name==current
Theme.tweenTo(chip,"BackgroundColor3",on and"selected"or"input",0.1)
Theme.tweenTo(chip,"TextColor3",on and"heading"or"muted",0.1)
local stroke_=chip:FindFirstChildWhichIsA("UIStroke")
if stroke_ then Theme.bind(stroke_,"Color",on and"accent"or"buttonEdge")stroke_.Transparency=on and 0.4 or 0.6 end
end
end
local function refresh()
if applying then return end
local now=match()
if now~=current then
local before=current
current=now
render()
if before~=nil and cfg.Callback then window:_safe("Presets",cfg.Callback,now)end
end
end
local function chip(name,order)
local button=create("TextButton",{
Name=name,AutoButtonColor=false,BorderSizePixel=0,Text=name,TextSize=9,Font=Enum.Font.GothamMedium,
Size=UDim2.fromOffset(Util.textWidth(name,9,Enum.Font.GothamMedium)+16,18),LayoutOrder=order,Parent=holder,
})
corner(button,9)
stroke(button,nil,0.6)
chips[name]=button
button.Activated:Connect(function()require("sounds").Play("click")selector:Select(name)end)
return button
end
function selector:Select(name)
name=tostring(name)
if name=="Custom"then
if custom then
applying=true
for flag,value in pairs(custom)do window:SetFlag(flag,value)end
applying=false
end
refresh()
return
end
for _,preset in ipairs(presets)do
if preset.name==name then
if current=="Custom"then
custom={}
for _,other in ipairs(presets)do
for _,flag in ipairs(flags(other.values))do custom[flag]=window.Lib.Flags[flag]end
end
end
applying=true
for flag,value in pairs(preset.values)do window:SetFlag(flag,value)end
applying=false
refresh()
return
end
end
end
function selector:Get()return current end
function selector:Add(name,values)
if type(values)~="table"then return end
presets[#presets+1]={name=tostring(name),values=values}
chip(tostring(name),#presets)
if chips.Custom then chips.Custom.LayoutOrder=#presets+1 end
current=nil
refresh()
end
for index,preset in ipairs(presets)do chip(preset.name,index)end
if showCustom then chip("Custom",#presets+1)end
window._dependents=window._dependents or{}
table.insert(window._dependents,function()
if not holder.Parent then return false end
refresh()
return true
end)
task.defer(refresh)
return selector
end
local function sub(card,body)
return setmetatable({page=card.page,window=card.window,order=0,body=body,frame=card.frame,title=card.title},Card)
end
function Card:Section(cfg)
if type(cfg)=="string"then cfg={Title=cfg}end
cfg=cfg or{}
local holder=create("Frame",{Name="Section_"..tostring(cfg.Title or""),BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=self:_order(),Parent=self.body})
Util.list(holder,4)
local head=create("TextButton",{Name="Header",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,cfg.Desc and 34 or 24),LayoutOrder=1,Parent=holder})
local line=create("Frame",{Name="Line",AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,Parent=head})
Theme.bind(line,"BackgroundColor3","line")
local x=0
local icon=cfg.Icon and Icons.themed(head,cfg.Icon,13,"accent",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0,11)})
if icon then x=20 end
local title=label(head,tostring(cfg.Title or""),11,{Name="Title",Position=UDim2.fromOffset(x,1),Size=UDim2.new(1,-x-24,0,20),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3","heading")
if cfg.Desc then
local desc=label(head,tostring(cfg.Desc),9,{Name="Desc",Position=UDim2.fromOffset(x,18),Size=UDim2.new(1,-x-24,0,12)})
Theme.bind(desc,"TextColor3","muted")
end
local chevron=create("Frame",{Name="Chevron",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0,11),Size=UDim2.fromOffset(10,10),Parent=head})
for index,rotation in ipairs({45,-45})do
local bar=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(index==1 and 3 or 7,5),Size=UDim2.fromOffset(6,1.5),Rotation=rotation,BorderSizePixel=0,Parent=chevron})
Theme.bind(bar,"BackgroundColor3","muted")
end
local body=create("Frame",{Name="Body",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2,Parent=holder})
Util.list(body,4)
Util.padding(body,0,0,2,4)
local section=sub(self,body)
if cfg.DependsOn then require("elements/base").depend(self.window,cfg.DependsOn,function(ok)holder.Visible=ok return holder.Parent~=nil end)end
function section:SetOpen(open)
self.Opened=open~=false
body.Visible=self.Opened
Util.tween(chevron,0.15,{Rotation=self.Opened and 0 or-90})
end
function section:ToggleOpen()self:SetOpen(not self.Opened)end
section.Header=head
head.Activated:Connect(function()section:SetOpen(not section.Opened)end)
section:SetOpen(cfg.Opened~=false)
return section
end
function Card:Row(cfg)
cfg=cfg or{}
local gap=tonumber(cfg.Gap)or 6
local weights=type(cfg.Widths)=="table"and cfg.Widths or nil
local holder=create("Frame",{Name="Row",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=self:_order(),Parent=self.body})
Util.list(holder,gap,Enum.FillDirection.Horizontal)
local function share()
local children={}
for _,child in ipairs(holder:GetChildren())do if child:IsA("GuiObject")and child.Visible then children[#children+1]=child end end
table.sort(children,function(a,b)return a.LayoutOrder<b.LayoutOrder end)
local n=#children
local total=0
for index=1,n do total=total+math.max(tonumber(weights and weights[index])or 1,0.05)end
for index,child in ipairs(children)do
local share=math.max(tonumber(weights and weights[index])or 1,0.05)/total
child.Size=UDim2.new(share,-gap*(n-1)*share,child.Size.Y.Scale,child.Size.Y.Offset)
end
end
holder.ChildAdded:Connect(function(child)
if child:IsA("GuiObject")then child:GetPropertyChangedSignal("Visible"):Connect(function()task.defer(share)end)end
task.defer(share)
end)
holder.ChildRemoved:Connect(function()task.defer(share)end)
return sub(self,holder)
end
function Card:Group(cfg)
if type(cfg)=="string"then cfg={Title=cfg}end
cfg=cfg or{}
local box=create("Frame",{Name="Group_"..tostring(cfg.Title or""),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,LayoutOrder=self:_order(),Parent=self.body})
Theme.bind(box,"BackgroundColor3","base")
box.BackgroundTransparency=0.35
corner(box,7)
Theme.bind(stroke(box),"Color","line")
Util.padding(box,10,10,6,8)
Util.list(box,4)
if cfg.Title then
local title=label(box,tostring(cfg.Title):upper(),8,{Name="Title",Size=UDim2.new(1,0,0,14),Font=Enum.Font.GothamMedium,LayoutOrder=0})
Theme.bind(title,"TextColor3","muted")
end
return sub(self,box)
end
function Card:SetTitle(text)if self.titleLabel then self.titleLabel.Text=tostring(text)end end
function Card:SetVisible(visible)self.frame.Visible=visible~=false end
return Card
end
__modules["config"]=function()
local Util=require("util")
local HttpService=Util.Services.HttpService
local Config={}
Config.__index=Config
local function can(...)
local available={
isfolder=isfolder,makefolder=makefolder,writefile=writefile,readfile=readfile,
isfile=isfile,delfile=delfile,listfiles=listfiles,
}
for _,name in ipairs({...})do
if type(available[name])~="function"then return false end
end
return true
end
local RESERVED={con=true,prn=true,aux=true,nul=true}
for i=1,9 do RESERVED["com"..i]=true RESERVED["lpt"..i]=true end
local function cleanName(name)
name=tostring(name or""):gsub("[^%w_%- ]",""):gsub("^%s+",""):gsub("%s+$","")
name=name:sub(1,60):gsub("%s+$","")
if RESERVED[name:lower()]then name=name.."_"end
return name
end
function Config.new(window,folder)
local self=setmetatable({window=window,folder=cleanName(folder)~=""and cleanName(folder)or"QustahUI"},Config)
self.path=self.folder.."/configs"
self.pending={}
self.Defaults={}
self.Custom={}
return self
end
function Config:_elementReady(flag,element)
if self.Defaults[flag]==nil then
local ok,value=pcall(element._save,element)
if ok and value~=nil then self.Defaults[flag]=value end
end
if element._initReset then pcall(element._initReset,element,self.Defaults[flag])end
local value=self.pending[flag]
if value~=nil then
self.pending[flag]=nil
pcall(element._load,element,value)
end
end
function Config:SetData(key,value)self.Custom[tostring(key)]=value end
function Config:GetData(key)return self.Custom[tostring(key)]end
function Config:OnDataLoaded(callback)
self._dataListeners=self._dataListeners or{}
table.insert(self._dataListeners,callback)
end
function Config:_setCustom(custom)
self.Custom=type(custom)=="table"and custom or{}
for _,listener in ipairs(self._dataListeners or{})do Util.safe(listener,self.Custom)end
end
function Config:SetPerGame(mode)
if mode==true then mode="Game"end
self.perGame=(mode=="Game"or mode=="Place")and mode or nil
local id=self.perGame=="Place"and game.PlaceId or(self.perGame=="Game"and game.GameId)or nil
self.path=self.folder.."/configs"..(id and("/"..tostring(id))or"")
self:_setActive(nil,nil)
end
function Config:_scopeFile(name)
return(self.perGame and self.path or self.folder).."/"..name
end
function Config:_ensure()
if not can("isfolder","makefolder")then return false end
if not isfolder(self.folder)then makefolder(self.folder)end
if not isfolder(self.folder.."/configs")then makefolder(self.folder.."/configs")end
if not isfolder(self.path)then makefolder(self.path)end
return true
end
function Config:Save(name)
name=cleanName(name)
if name==""then return false,"Empty config name"end
if not can("writefile")then return false,"writefile is not available"end
self:_ensure()
local data={version=1,flags=self:Snapshot(),custom=self.Custom}
local ok,err=Util.writeAtomic(self.path.."/"..name..".json",HttpService:JSONEncode(data))
if not ok then return false,err end
self:_setActive(name,data.flags)
return true
end
function Config:SaveFlags(name,flags,custom)
name=cleanName(name)
if name==""then return false,"Empty config name"end
if not can("writefile")then return false,"writefile is not available"end
self:_ensure()
local ok,err=Util.writeAtomic(self.path.."/"..name..".json",HttpService:JSONEncode({version=1,flags=flags or{},custom=custom}))
if not ok then return false,err end
return true
end
function Config:_readFile(file,label)
local data,info=Util.readJSON(file)
if data and info==true then
self.Recovered=self.Recovered or{}
table.insert(self.Recovered,label or file)
for _,listener in ipairs(self._recoverListeners or{})do Util.safe(listener,label or file)end
end
return data,info
end
function Config:OnRecovered(callback)
self._recoverListeners=self._recoverListeners or{}
table.insert(self._recoverListeners,callback)
end
function Config:_readProfile(name)
if not can("readfile","isfile")then return nil,"readfile is not available"end
local data,problem=self:_readFile(self.path.."/"..name..".json",name)
if not data then return nil,problem=="missing"and"Config not found"or"Config file is damaged"end
if type(data.flags)~="table"then return nil,"Config file is damaged"end
return data
end
function Config:Load(name)
name=cleanName(name)
local data,err=self:_readProfile(name)
if not data then return false,err end
local failed=self:Apply(data.flags)
self:_setCustom(data.custom)
self:_setActive(name,data.flags)
if failed>0 then return true,failed.." setting(s) could not be applied"end
return true
end
function Config:Read(name)
local data,err=self:_readProfile(cleanName(name))
if not data then return nil,err end
return data.flags,data.custom
end
function Config:_setActive(name,flags)
self.Active,self.ActiveFlags=name,flags
for _,listener in ipairs(self._activeListeners or{})do Util.safe(listener,name)end
end
function Config:OnActiveChanged(callback)
self._activeListeners=self._activeListeners or{}
table.insert(self._activeListeners,callback)
end
local function same(a,b)
if type(a)=="number"and type(b)=="number"then return math.abs(a-b)<1e-6 end
if type(a)~="table"or type(b)~="table"then return a==b end
for key,value in pairs(a)do if not same(value,b[key])then return false end end
for key in pairs(b)do if a[key]==nil then return false end end
return true
end
Config.same=same
function Config:Changes(flags)
flags=flags or self.ActiveFlags or self.DefaultFlags or{}
local count,names=0,{}
for flag,value in pairs(self:Snapshot())do
if flags[flag]~=nil and not same(value,flags[flag])then
count=count+1
names[#names+1]=flag
end
end
return count,names
end
function Config:Export(name)
local flags,custom
if name then flags,custom=self:Read(name)else flags,custom=self:Snapshot(),self.Custom end
if not flags then return nil,"Config not found"end
local data={n=name or"Shared",f=flags}
if type(custom)=="table"and next(custom)~=nil then data.c=custom end
return"QUSTAH1:"..Util.base64encode(HttpService:JSONEncode(data))
end
function Config:Decode(code)
code=tostring(code or""):gsub("%s","")
local body=code:match("^QUSTAH1:(.+)$")
if not body then return nil,"Not a profile code"end
local json=Util.base64decode(body)
local ok,data=pcall(function()return HttpService:JSONDecode(json)end)
if not ok or type(data)~="table"or type(data.f)~="table"then return nil,"The code is damaged or cut off"end
return cleanName(data.n)~=""and cleanName(data.n)or"Imported",data.f,data.c
end
function Config:FreeName(name)
name=cleanName(name)
if name==""or name:lower()=="default"then name="Profile"end
if not self:Exists(name)then return name end
local index=2
while self:Exists(name.." "..index)do index=index+1 end
return name.." "..index
end
function Config:Delete(name)
name=cleanName(name)
if self.Active==name then self:_setActive(nil,nil)end
if not can("delfile","isfile")then return false,"delfile is not available"end
local file=self.path.."/"..name..".json"
if not isfile(file)then return false,"Config not found"end
local ok,err=pcall(delfile,file)
return ok,not ok and tostring(err)or nil
end
function Config:List()
local names={}
if not can("listfiles","isfolder")or not isfolder(self.path)then return names end
local ok,files=pcall(listfiles,self.path)
if not ok or type(files)~="table"then return names end
local seen={}
for _,file in ipairs(files)do
local path=tostring(file):gsub("\\","/")
local name=path:match("([^/]+)%.json$")or path:match("([^/]+)%.json%.tmp$")
local parent=path:match("^(.*)/[^/]+$")or""
if name and not seen[name]and(parent==""or parent:sub(-#self.path)==self.path)then
seen[name]=true
names[#names+1]=name
end
end
table.sort(names)
return names
end
function Config:SetAutoLoad(name)
if not can("writefile")then return false end
self:_ensure()
return Util.writeAtomic(self:_scopeFile("autoload.txt"),cleanName(name))
end
function Config:GetAutoLoad()
if not can("readfile","isfile")or not isfile(self:_scopeFile("autoload.txt"))then return nil end
local ok,name=pcall(readfile,self:_scopeFile("autoload.txt"))
name=ok and cleanName(name)or""
return name~=""and name or nil
end
function Config:LoadAutoLoad()
local name=self:GetAutoLoad()
if name and self:Exists(name)then return self:Load(name)end
return false,"No autoload config"
end
function Config:ReadMemory()
return self:_readFile(self.folder.."/window.json","window")or{}
end
function Config:WriteMemory(data)
if not can("writefile")then return false end
self:_ensure()
return Util.writeAtomic(self.folder.."/window.json",HttpService:JSONEncode(data))
end
function Config:ReadJSON(name)
return self:_readFile(self.folder.."/"..cleanName(name)..".json",cleanName(name))or{}
end
function Config:WriteJSON(name,data)
if not can("writefile")then return false end
self:_ensure()
return Util.writeAtomic(self.folder.."/"..cleanName(name)..".json",HttpService:JSONEncode(data))
end
function Config:ReadMeta()
return self:_readFile(self:_scopeFile("profiles.json"),"profiles")or{}
end
function Config:WriteMeta(data)
if not can("writefile")then return false end
self:_ensure()
return Util.writeAtomic(self:_scopeFile("profiles.json"),HttpService:JSONEncode(data))
end
function Config:Snapshot()
local data={}
for flag,value in pairs(self.pending)do data[flag]=value end
for flag,element in pairs(self.window.flags)do
local ok,value=pcall(element._save,element)
if ok and value~=nil then data[flag]=value end
end
return data
end
function Config:Apply(flags)
local failed=0
for flag,value in pairs(flags or{})do
local element=self.window.flags[flag]
if element and self.Defaults[flag]==nil then
local ok,current=pcall(element._save,element)
if ok and current~=nil then self.Defaults[flag]=current end
end
if not element then
self.pending[flag]=value
elseif not pcall(element._load,element,value)then
failed=failed+1
end
end
return failed
end
function Config:Exists(name)
name=cleanName(name)
if not can("isfile")or name==""then return false end
local file=self.path.."/"..name..".json"
return isfile(file)or isfile(file..".tmp")
end
function Config:Rename(old,new)
old,new=cleanName(old),cleanName(new)
if new==""then return false,"Empty name"end
if self:Exists(new)then return false,"A profile with that name exists"end
if not can("readfile","writefile","delfile","isfile")then return false,"File functions are not available"end
local ok,text=pcall(readfile,self.path.."/"..old..".json")
if not ok then return false,"Profile not found"end
local written,err=Util.writeAtomic(self.path.."/"..new..".json",text)
if not written then return false,err end
pcall(delfile,self.path.."/"..old..".json")
if self:GetAutoLoad()==old then self:SetAutoLoad(new)end
if self.Active==old then self:_setActive(new,self.ActiveFlags)end
return true
end
function Config:Copy(name,new)
name,new=cleanName(name),cleanName(new)
if self:Exists(new)then return false,"A profile with that name exists"end
if not can("readfile","writefile")then return false,"File functions are not available"end
local ok,text=pcall(readfile,self.path.."/"..name..".json")
if not ok then return false,"Profile not found"end
return Util.writeAtomic(self.path.."/"..new..".json",text)
end
function Config:ClearAutoLoad()
if can("delfile","isfile")and isfile(self:_scopeFile("autoload.txt"))then pcall(delfile,self:_scopeFile("autoload.txt"))end
end
return Config
end
__modules["dashboard"]=function()
local Util=require("util")
local Theme=require("theme")
local Glow=require("glow")
local Services=Util.Services
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(window,cfg)
cfg=cfg or{}
local Players=Services.Players
local player=Players.LocalPlayer
local tab=window:Tab({Title=cfg.Title or"Dashboard",Icon=cfg.Icon or"layout-dashboard",Header=cfg.Header~=false})
window._dividerNext=true
local page=tab:Page(tab.Title)
local started=os.clock()
local profile=page:Card({Wide=true})
local body=create("Frame",{Name="Profile",BackgroundTransparency=1,Size=UDim2.new(1,0,0,68),LayoutOrder=profile:_order(),Parent=profile.body})
local ring=create("Frame",{Name="Ring",Position=UDim2.fromOffset(0,2),Size=UDim2.fromOffset(62,62),BorderSizePixel=0,BackgroundTransparency=0.85,Parent=body})
Theme.bind(ring,"BackgroundColor3","accent")
corner(ring,31)
local avatar=create("ImageLabel",{Name="Avatar",Position=UDim2.fromOffset(3,5),Size=UDim2.fromOffset(56,56),BorderSizePixel=0,Parent=body})
Theme.bind(avatar,"BackgroundColor3","input")
corner(avatar,28)
local online=create("Frame",{Name="Online",Position=UDim2.fromOffset(47,49),Size=UDim2.fromOffset(10,10),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(70,205,105),Parent=body})
corner(online,5)
Theme.bind(stroke(online,nil,0,2),"Color","card")
local display=label(body,player.DisplayName,15,{Name="DisplayName",Position=UDim2.fromOffset(76,10),Size=UDim2.new(1,-250,0,20)})
pcall(function()display.FontFace=Font.new(Font.fromEnum(Enum.Font.Gotham).Family,Enum.FontWeight.SemiBold)end)
Theme.bind(display,"TextColor3","heading")
local username=label(body,"@"..player.Name.." · #"..player.UserId,10,{Name="Username",Position=UDim2.fromOffset(76,32),Size=UDim2.new(1,-250,0,15)})
Theme.bind(username,"TextColor3","muted")
local caption=label(body,"SESSION",8,{Name="SessionCaption",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,12),Size=UDim2.fromOffset(150,12),TextXAlignment=Enum.TextXAlignment.Right})
Theme.bind(caption,"TextColor3","muted")
local uptime=label(body,"00:00:00",18,{Name="Uptime",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,28),Size=UDim2.fromOffset(150,24),TextXAlignment=Enum.TextXAlignment.Right})
Theme.bind(uptime,"TextColor3","accent")
Glow.add(display,{Base="heading",Phase=0.1})
Glow.add(uptime,{Base="accent",Phase=0.45})
local avatarImage=Util.avatar(player.UserId,150)
if not window.anonymous then avatar.Image=avatarImage end
if window.OnAnonymousChanged then
window:OnAnonymousChanged(function(on)
display.Text=on and"Anonymous"or player.DisplayName
username.Text=on and"hidden"or("@"..player.Name.." · #"..player.UserId)
avatar.Image=on and""or avatarImage
end)
end
local session=page:Card({Title="Session",Side="Left"})
local userId=session:Info({Title="User ID",Value="#"..player.UserId,Copy=function()return tostring(player.UserId)end})
if window.OnAnonymousChanged then window:OnAnonymousChanged(function(on)userId:Set(on and"hidden"or("#"..player.UserId))end)end
session:Info({Title="Account created",Value=os.date("%d %b %Y",os.time()-player.AccountAge*86400)})
local executor="Unknown"
pcall(function()
if type(identifyexecutor)=="function"then executor=table.concat({identifyexecutor()}," ")
elseif type(getexecutorname)=="function"then executor=tostring(getexecutorname())end
end)
session:Info({Title="Executor",Value=executor})
session:Divider()
session:Info({Title="Game ID",Value="#"..game.GameId,Copy=function()return tostring(game.GameId)end})
session:Info({Title="Place ID",Value="#"..game.PlaceId,Copy=function()return tostring(game.PlaceId)end})
local info=page:Card({Title="Info",Side="Right"})
if window.Version~=""then info:Info({Title="GUI version",Value=window.Version})end
for _,entry in ipairs(cfg.Info or{})do info:Info({Title=entry[1],Value=entry[2],Copy=entry.Copy})end
local playerCount=info:Info({Title="Players",Value="--"})
local ping=info:Info({Title="Ping",Value="--"})
if cfg.Server~=false then
local server=page:Card({Title="Server",Side="Right"})
local busy=false
local function teleport(hop)
if busy then window:Notify({Title="Server",Content="Teleport already pending"})return end
local TeleportService=Services.TeleportService
busy=true
task.delay(12,function()busy=false end)
window:Notify({Title=hop and"Server hop"or"Rejoin",Content=hop and"Finding a server..."or"Rejoining..."})
task.spawn(function()
local ok,err=pcall(function()
if not hop then
if game.JobId~=""and#Players:GetPlayers()>1 then
TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,player)
else
TeleportService:Teleport(game.PlaceId,player)
end
return
end
local url=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
local data=Services.HttpService:JSONDecode(game:HttpGet(url))
local list={}
for _,item in ipairs(data.data or{})do
if item.id~=game.JobId and item.playing and item.maxPlayers and item.playing<item.maxPlayers then list[#list+1]=item end
end
assert(#list>0,"No other public server found")
TeleportService:TeleportToPlaceInstance(game.PlaceId,list[math.random(1,#list)].id,player)
end)
if not ok then busy=false window:Notify({Title="Teleport failed",Content=tostring(err),Color="danger"})end
end)
end
server:Button({Title="Rejoin",Callback=function()teleport(false)end})
server:Button({Title="Server hop",Confirm=true,Callback=function()teleport(true)end})
server:Info({Title="Job ID",Value=game.JobId~=""and(game.JobId:sub(1,8).."...")or"studio",Copy=function()return game.JobId end})
end
if cfg.Modules~=false then
local modulesCard=page:Card({Title="Modules",Side="Left"})
local empty=modulesCard:Label("Modules report here with Window:SetModule(name, state)")
local rows={}
local COLORS={On="success",Limited="warning",Error="danger"}
local function update()
local order,modules=window:GetModules()
empty:SetVisible(#order==0)
for _,name in ipairs(order)do
rows[name]=rows[name]or modulesCard:Info({Title=name})
local module=modules[name]
rows[name]:Set(module.state)
rows[name]:SetColor(COLORS[module.state]or"muted")
end
end
window:OnStatusChanged(update)
update()
end
task.spawn(function()
while window.alive do
if window.visible and window.current==tab then
local seconds=math.floor(os.clock()-started)
uptime.Text=string.format("%02d:%02d:%02d",seconds//3600,(seconds//60)%60,seconds%60)
playerCount:Set(#Players:GetPlayers().." / "..Players.MaxPlayers)
local ok,value=pcall(function()return player:GetNetworkPing()end)
ping:Set(ok and(math.floor(value*1000+0.5).." ms")or"--")
end
task.wait(1)
end
end)
return tab
end
end
__modules["dialog"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
return function(Window)
function Window:Dialog(cfg)
cfg=cfg or{}
if self._dialog then self._dialog:Close()end
local window=self
local overlay=create("TextButton",{
Name="Dialog",Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),
BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=200,Parent=self.main,
})
local panel=create("Frame",{
Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(0,330,0,0),
AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,ZIndex=201,Active=true,Parent=overlay,
})
create("UISizeConstraint",{MaxSize=Vector2.new(330,400),MinSize=Vector2.new(200,0),Parent=panel})
Theme.bind(panel,"BackgroundColor3","card")
corner(panel,8)
Theme.bind(stroke(panel),"Color","line")
Util.padding(panel,16,16,12,12)
Util.list(panel,8)
local title=label(panel,tostring(cfg.Title or""),13,{
Name="Title",Size=UDim2.new(1,0,0,20),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,Font=Enum.Font.GothamMedium,ZIndex=202,LayoutOrder=1,
})
Theme.bind(title,"TextColor3","heading")
if cfg.Icon and Icons.Get(cfg.Icon)then
Util.padding(title,24,0,0,0)
local icon=Icons.themed(title,cfg.Icon,16,"accent",{Name="DialogIcon",Position=UDim2.fromOffset(-24,2),ZIndex=203})
if typeof(cfg.IconColor)=="Color3"then Theme.bind(icon,"ImageColor3",cfg.IconColor)end
end
if cfg.Content then
local content=label(panel,tostring(cfg.Content),10,{
Name="Content",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,TextYAlignment=Enum.TextYAlignment.Top,RichText=true,ZIndex=202,LayoutOrder=2,
})
Theme.bind(content,"TextColor3","muted")
end
local row=create("Frame",{Name="Buttons",BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=3,ZIndex=202,Parent=panel})
Util.list(row,8,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)
local dialog={Frame=overlay}
function dialog:Close(result)
if not overlay.Parent then return end
if window._dialog==dialog then window._dialog=nil end
overlay:Destroy()
if result==nil then window:_safe("Dialog",cfg.OnCancel)end
end
local buttons=cfg.Buttons or{{Title="OK"}}
for index,spec in ipairs(buttons)do
local style=spec.Style
local button=create("TextButton",{
Name=tostring(spec.Title or"OK"),Text=tostring(spec.Title or"OK"),TextSize=10,Font=Enum.Font.GothamMedium,
AutoButtonColor=false,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(70,28),
LayoutOrder=index,ZIndex=203,Parent=row,
})
Util.padding(button,14,14,0,0)
corner(button,6)
local outline=stroke(button)
if style=="Danger"then
Theme.bind(button,"BackgroundColor3","dangerDeep")
Theme.bind(button,"TextColor3","dangerText")
Theme.bind(outline,"Color","dangerEdge")
elseif style=="Primary"then
Theme.bind(button,"BackgroundColor3","accentDeep")
Theme.bind(button,"TextColor3","accent")
Theme.bind(outline,"Color","accent")
outline.Transparency=0.45
else
Theme.bind(button,"BackgroundColor3","input")
Theme.bind(button,"TextColor3","text")
Theme.bind(outline,"Color","buttonEdge")
end
button.Activated:Connect(function()
dialog:Close(true)
window:_safe("Dialog",spec.Callback)
end)
end
overlay.Activated:Connect(function()dialog:Close()end)
tween(overlay,0.15,{BackgroundTransparency=0.35})
self._dialog=dialog
return dialog
end
function Window:Confirm(title,content,onConfirm,confirmText,danger)
return self:Dialog({
Title=title,Content=content,Icon=danger and"triangle-alert"or nil,IconColor=danger and Theme.get("danger")or nil,
Buttons={{Title="Cancel"},{Title=confirmText or"Confirm",Style=danger and"Danger"or"Primary",Callback=onConfirm}},
})
end
end
end
__modules["elements/actioninput"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local GREEN,RED="success","danger"
return function(card,cfg)
local holder=create("Frame",{Name=tostring(cfg.Name or cfg.Button or"ActionInput"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=card:_order(),Parent=card.body})
Util.list(holder,5)
local field=create("Frame",{Name="Field",Size=UDim2.new(1,0,0,34),BorderSizePixel=0,LayoutOrder=1,Parent=holder})
Theme.bind(field,"BackgroundColor3","input")
corner(field,8)
local outline=stroke(field)
Theme.bind(outline,"Color","buttonEdge")
local left=12
local icon=cfg.Icon and Icons.themed(field,cfg.Icon,14,"muted",{Name="FieldIcon",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,11,0.5,0)})
if icon then left=33 end
local buttonText=tostring(cfg.Button or"OK")
local buttonWidth=Util.textWidth(buttonText,10,Enum.Font.GothamMedium)+26
local button=create("TextButton",{
Name="Action",Text=buttonText,TextSize=10,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-5,0.5,0),Size=UDim2.fromOffset(buttonWidth,24),Parent=field,
})
corner(button,6)
local buttonEdge=stroke(button)
local box=create("TextBox",{
Name="Box",Text="",PlaceholderText=tostring(cfg.Placeholder or""),TextSize=10,Font=Enum.Font.Gotham,
TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BackgroundTransparency=1,ClipsDescendants=true,
Position=UDim2.fromOffset(left,0),Size=UDim2.new(1,-(left+buttonWidth+14),1,0),Parent=field,
})
Theme.bind(box,"TextColor3","heading")
Theme.bind(box,"PlaceholderColor3","muted")
local hintRow=create("Frame",{Name="HintRow",BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),LayoutOrder=2,Parent=holder})
local hintDot=create("Frame",{Name="Dot",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,3,0.5,0),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Visible=false,Parent=hintRow})
corner(hintDot,3)
local hint=label(hintRow,tostring(cfg.Hint or""),9,{Name="Hint",Position=UDim2.fromOffset(2,0),Size=UDim2.new(1,-2,1,0)})
Theme.bind(hint,"TextColor3","muted")
hintRow.Visible=cfg.Hint~=nil or cfg.Validate~=nil
local element=Base.element(card,"ActionInput",cfg,holder,nil,nil)
element.Value=""
local ready=false
local function style()
Theme.tweenTo(button,"BackgroundColor3",ready and"accentDeep"or"base",0.1)
Theme.tweenTo(button,"TextColor3",ready and"accent"or"muted",0.1)
Theme.tweenTo(buttonEdge,"Color",ready and"accent"or"line",0.1)
buttonEdge.Transparency=ready and 0.45 or 0
end
function element:SetHint(text,state)
hintRow.Visible=true
hint.Text=tostring(text or cfg.Hint or"")
local color=state=="ok"and GREEN or(state=="error"and RED or nil)
hintDot.Visible=color~=nil
hint.Position=UDim2.fromOffset(color and 13 or 2,0)
if color then Theme.bind(hint,"TextColor3",color)Theme.bind(hintDot,"BackgroundColor3",color)else Theme.bind(hint,"TextColor3","muted")end
end
local function validate()
local text=box.Text:gsub("^%s+",""):gsub("%s+$","")
element.Value=text
if text==""then
ready=false
element:SetHint(cfg.Hint)
elseif type(cfg.Validate)=="function"then
local okCall,ok,message=pcall(cfg.Validate,text)
if not okCall then ok,message=false,tostring(ok)end
ready=ok~=false
if message then element:SetHint(message,ok==true and"ok"or(ok==false and"error"or nil))else element:SetHint(cfg.Hint)end
else
ready=true
end
style()
end
local function run()
validate()
if not ready or element.Locked then return end
element:_call(cfg.Callback,element.Value)
if cfg.ClearOnAction~=false then box.Text=""end
validate()
end
box:GetPropertyChangedSignal("Text"):Connect(validate)
box.Focused:Connect(function()Theme.tweenTo(outline,"Color","accent",0.12)outline.Transparency=0.4 end)
box.FocusLost:Connect(function(enter)
Theme.tweenTo(outline,"Color","buttonEdge",0.12)
outline.Transparency=0
if enter then run()end
end)
button.Activated:Connect(run)
button.MouseEnter:Connect(function()if ready then Theme.tweenTo(button,"TextColor3","heading",0.1)end end)
button.MouseLeave:Connect(style)
function element:Set(text)box.Text=tostring(text or"")validate()end
function element:Get()return self.Value end
function element:Focus()pcall(function()box:CaptureFocus()end)end
function element:Run()run()end
validate()
return Base.finish(element,cfg)
end
end
__modules["elements/base"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local Sounds=require("sounds")
local create,corner,label=Util.create,Util.corner,Util.label
local Base={}
local VALUE={
Toggle=true,Slider=true,Dropdown=true,Keybind=true,ColorPicker=true,Input=true,Segment=true,
Range=true,Swatches=true,Gradient=true,ImagePicker=true,PlayerList=true,Checkbox=true,Radio=true,Stepper=true,TextArea=true,
}
local function truthy(value)
if value==nil or value==false or value==""then return false end
if type(value)=="table"then return next(value)~=nil end
if typeof(value)=="EnumItem"then return value.Name~="None"and value.Name~="Unknown"end
return true
end
Base.truthy=truthy
function Base.depend(window,spec,apply)
local check
if type(spec)=="function"then
check=function()return spec(window.Lib.Flags)end
else
if type(spec)~="table"then spec={Flag=spec}end
check=function()
local value=window.Lib.Flags[spec.Flag]
local ok
if type(spec.Value)=="function"then ok=spec.Value(value)
elseif spec.Value~=nil then
if type(value)=="table"then ok=table.find(value,spec.Value)~=nil else ok=value==spec.Value end
else ok=truthy(value)end
if spec.Not then ok=not ok end
return ok
end
end
local function run()
local ok,result=pcall(check)
return apply(ok and result and true or false)~=false
end
window._dependents=window._dependents or{}
table.insert(window._dependents,run)
task.defer(run)
return run
end
local function rowsOf(parent)
local list={}
for _,child in ipairs(parent:GetChildren())do
if child:IsA("GuiObject")and child.LayoutOrder>=2 and child.LayoutOrder%2==0 then list[#list+1]=child end
end
table.sort(list,function(a,b)return a.LayoutOrder<b.LayoutOrder end)
return list
end
local function panelOf(row)
local parent=row.Parent
if not parent then return nil end
for _,child in ipairs(parent:GetChildren())do
if child~=row and child:IsA("GuiObject")and child.LayoutOrder==row.LayoutOrder+1 then return child end
end
end
function Base.row(card,cfg,height,opts)
opts=opts or{}
local row=create(opts.button and"TextButton"or"Frame",{
Name=tostring(cfg.Title or"Row"),BackgroundTransparency=1,BorderSizePixel=0,
Size=UDim2.new(1,0,0,height),LayoutOrder=card:_order(),Parent=card.body,
})
if opts.button then row.Text=""row.AutoButtonColor=false end
local right=opts.right or 0
local title=label(row,tostring(cfg.Title or""),11,{
Name="Title",Position=UDim2.fromOffset(0,cfg.Desc and 3 or 0),
Size=UDim2.new(1,-right,0,cfg.Desc and 18 or(opts.titleHeight or height)),
})
Theme.bind(title,"TextColor3",cfg.Risky and"danger"or"text")
if type(cfg.Risky)=="string"and not cfg.Help then cfg.Help=cfg.Risky end
local desc
if cfg.Desc then
desc=label(row,tostring(cfg.Desc),9,{Name="Desc",Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,-right,0,14)})
Theme.bind(desc,"TextColor3","muted")
end
if cfg.Icon and not opts.noIcon then
local icon=Icons.themed(row,cfg.Icon,14,"muted",{Name="RowIcon",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0,cfg.Desc and 12 or height/2)})
if icon then
title.Position=UDim2.new(0,22,0,title.Position.Y.Offset)
title.Size=UDim2.new(1,title.Size.X.Offset-22,0,title.Size.Y.Offset)
if desc then desc.Position=UDim2.fromOffset(22,23)desc.Size=UDim2.new(1,desc.Size.X.Offset-22,0,14)end
end
end
if cfg.Help then
local help=create("TextButton",{
Name="Help",Text="i",TextSize=10,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BackgroundTransparency=1,
AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-(opts.helpRight or right),0,opts.helpY or height/2),
Size=UDim2.fromOffset(14,16),ZIndex=5,Parent=row,
})
Theme.bind(help,"TextColor3","muted")
help.Activated:Connect(function()card.window:_tip(cfg.Help)end)
help.MouseLeave:Connect(function()card.window:_hideTip()end)
title.Size=UDim2.new(1,-(opts.helpRight or right)-16,0,title.Size.Y.Offset)
end
return row,title,desc
end
local function same(a,b)
if type(a)~=type(b)then return false end
if type(a)~="table"then return a==b end
for key,value in pairs(a)do if not same(value,b[key])then return false end end
for key in pairs(b)do if a[key]==nil then return false end end
return true
end
local function copy(value)
if type(value)~="table"then return value end
local out={}
for key,item in pairs(value)do out[key]=copy(item)end
return out
end
function Base.element(card,kind,cfg,row,title,desc)
local window=card.window
if cfg.Flag==nil and VALUE[kind]and cfg.Title and window.cfg and window.cfg.AutoFlags and not window._noAutoFlags then
cfg.Flag=window:_autoFlag(card,cfg.Title)
end
local element={Type=kind,Title=cfg.Title,Flag=cfg.Flag,Row=row,Card=card,Locked=false,_changed={}}
function element:OnChanged(callback)
self._changed[#self._changed+1]=callback
return self
end
function element:_call(callback,...)
local ok=window:_safe(tostring(self.Title or kind),callback,...)
if ok==false then
self._failed=true
Base.failed(self,title)
end
return ok
end
function element:_accepted(kind)
if cfg.Flash~=false and not self._failed then self:Flash(kind or"success")end
end
function element:_fire(value,silent,...)
if self.Flag then
window.Lib.Flags[self.Flag]=value
window:_flagChanged(self.Flag)
end
if self._resetButton then self:_updateReset()end
if silent then return end
local dragging=...
if not(kind=="Slider"and dragging==true)then Sounds.Play((kind=="Toggle"or kind=="Checkbox")and"toggle"or"click")end
self:_call(cfg.Callback,value,...)
for _,callback in ipairs(self._changed)do self:_call(callback,value,...)end
end
function element:SetTitle(text)
self.Title=text
if self._errorShown then self._titleBefore=tostring(text)elseif title then title.Text=tostring(text)end
end
function element:SetDesc(text)
self._descText=tostring(text)
if desc and not self.Locked then desc.Text=self._descText end
end
function element:SetVisible(visible)row.Visible=visible~=false end
function element:_initReset(default)
if self._resetButton or default==nil or kind=="Button"then return end
if not title or not title:IsA("TextLabel")or title.Text==""then return end
if cfg.Reset==false or(window.cfg and window.cfg.ResetButtons==false)then return end
if type(self.Flag)=="string"and self.Flag:sub(1,2)=="__"then return end
self._default=copy(default)
local button=create("ImageButton",{
Name="Reset",BackgroundTransparency=1,AutoButtonColor=false,Image="",AnchorPoint=Vector2.new(0,0.5),
Size=UDim2.fromOffset(16,16),ZIndex=6,Visible=false,Parent=row,
})
local icon=Icons.themed(button,"rotate-ccw",11,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=6})
button.MouseEnter:Connect(function()
if icon then Theme.tweenTo(icon,"ImageColor3","heading",0.1)end
window:_tip("Reset to default")
end)
button.MouseLeave:Connect(function()
if icon then Theme.tweenTo(icon,"ImageColor3","muted",0.1)end
window:_hideTip()
end)
button.Activated:Connect(function()
Sounds.Play("click")
window:_hideTip()
self:ResetToDefault()
end)
self._resetButton=button
title:GetPropertyChangedSignal("Text"):Connect(function()self:_updateReset()end)
self:_updateReset()
end
function element:_updateReset()
local button=self._resetButton
if not button then return end
local ok,current=pcall(self._save,self)
button.Visible=ok and not same(current,self._default)and not self._errorShown
if not button.Visible then return end
local width=Util.textWidth(title.Text,title.TextSize,title.Font)
local room=title.AbsoluteSize.X
if room and room>20 then width=math.min(width,room-18)end
local x=title.Position.X.Offset+width+5
local badge=row:FindFirstChild("Badge")
if badge then x=badge.Position.X.Offset+badge.Size.X.Offset+3 end
button.Position=UDim2.new(0,x,0,title.Position.Y.Offset+title.Size.Y.Offset/2)
end
function element:ResetToDefault()
if self.Locked or self._default==nil then return end
pcall(self._load,self,copy(self._default))
self:_updateReset()
self:Flash("accent")
end
function element:Flash(kind)Base.flash(row,kind)end
function element:Lock(reason)
self.Locked=true
self._lockReason=reason
if self.SetOpen then pcall(self.SetOpen,self,false)end
local popup=window._popup
if popup and popup.owner and(popup.owner==row or popup.owner:IsDescendantOf(row))then window:_closePopup()end
if not self._lock then
local cover=create("TextButton",{
Name="Lock",Text="",AutoButtonColor=false,BackgroundTransparency=0.45,BorderSizePixel=0,
Position=UDim2.fromOffset(-4,-2),Size=UDim2.new(1,8,1,4),ZIndex=20,Parent=row,
})
Theme.bind(cover,"BackgroundColor3","card")
corner(cover,6)
cover.MouseEnter:Connect(function()if self._lockReason then window:_tip(self._lockReason)end end)
cover.MouseLeave:Connect(function()window:_hideTip()end)
self._lock=cover
local pill=create("Frame",{
Name="Reason",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),
Size=UDim2.new(0.7,0,0,16),ZIndex=21,Visible=false,Parent=cover,
})
local icon=Icons.themed(pill,"lock",11,"warning",{Name="LockIcon",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),ZIndex=22})
local text=label(pill,"",9,{Name="Text",Size=UDim2.new(1,icon and-16 or 0,1,0),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,ZIndex=22})
Theme.bind(text,"TextColor3","warning")
self._lockPill,self._lockText=pill,text
end
local hasReason=reason~=nil and reason~=""
if desc then
if self._descText==nil then self._descText=desc.Text end
if hasReason then
desc.Text=tostring(reason)
desc.ZIndex=21
Theme.bind(desc,"TextColor3","warning")
end
self._lockPill.Visible=false
else
self._lockText.Text=hasReason and tostring(reason)or""
self._lockPill.Visible=hasReason
end
self._lock.Visible=true
end
function element:Unlock()
self.Locked=false
if self._lock then self._lock.Visible=false end
if desc and self._descText~=nil then
desc.Text=self._descText
desc.ZIndex=1
Theme.bind(desc,"TextColor3","muted")
end
window:_hideTip()
end
function element:GetIndex()
if not row.Parent then return nil end
for index,item in ipairs(rowsOf(row.Parent))do if item==row then return index end end
end
function element:MoveTo(index)
local parent=row.Parent
if not parent then return end
local list=rowsOf(parent)
local orders,panels={},{}
for i,item in ipairs(list)do orders[i]=item.LayoutOrder panels[item]=panelOf(item)end
for i,item in ipairs(list)do if item==row then table.remove(list,i)break end end
index=math.clamp(math.floor(tonumber(index)or 1),1,#list+1)
table.insert(list,index,row)
for i,item in ipairs(list)do
item.LayoutOrder=orders[i]
if panels[item]then panels[item].LayoutOrder=orders[i]+1 end
end
end
function element:MoveUp()local index=self:GetIndex()if index then self:MoveTo(index-1)end end
function element:MoveDown()local index=self:GetIndex()if index then self:MoveTo(index+1)end end
function element:Destroy()
if self.Flag and window.flags[self.Flag]==self then window.flags[self.Flag]=nil end
window.binds[self]=nil
local panel=panelOf(row)
if panel then panel:Destroy()end
row:Destroy()
window:_hideTip()
end
function element:Remove()self:Destroy()end
function element:_save()return self.Value end
function element:_load(value)self:Set(value)end
element._risky=cfg.Risky and true or false
if cfg.Flag then window:_register(cfg.Flag,element)end
element._tooltip=cfg.Tooltip
function element:SetTooltip(text)self._tooltip=text end
function element:_setConflict(others)
local on=others~=nil and#others>0
self.KeyConflict=on and others or nil
self._conflictTip=on and("Key also used by: "..table.concat(others,", "))or nil
if self._keyLabel then
if self._keyRole==nil then self._keyRole=(Theme._binding(self._keyLabel)or{}).TextColor3 or"muted"end
Theme.bind(self._keyLabel,"TextColor3",on and"warning"or self._keyRole)
end
if self._keyStroke then
if self._keyStrokeRole==nil then self._keyStrokeRole=(Theme._binding(self._keyStroke)or{}).Color or"buttonEdge"end
Theme.bind(self._keyStroke,"Color",on and"warning"or self._keyStrokeRole)
end
if self._onConflict then self:_onConflict(on)end
end
local hoverToken=0
local function cutText()
local parts={}
for _,object in ipairs({title,desc,row:FindFirstChild("Value")})do
if object and object:IsA("GuiObject")and object.Visible and object.Text~=""then
local ok,fits=pcall(function()return object.TextFits end)
if ok and fits==false then parts[#parts+1]=object.Text end
end
end
return#parts>0 and table.concat(parts," · ")or nil
end
local tipShown=false
row.MouseEnter:Connect(function()
hoverToken=hoverToken+1
local token=hoverToken
task.delay(0.35,function()
if token~=hoverToken or element.Locked or not row.Parent then return end
local text=element._conflictTip or element._tooltip or cutText()
if text then tipShown=true window:_tip(text)end
end)
end)
row.MouseLeave:Connect(function()
hoverToken=hoverToken+1
if tipShown then tipShown=false window:_hideTip()end
end)
if cfg.DependsOn then
local spec=cfg.DependsOn
local mode=type(spec)=="table"and spec.Mode or"Lock"
local function reason()
if type(spec)=="table"and spec.Reason then return spec.Reason end
local flag=type(spec)=="table"and spec.Flag or(type(spec)=="string"and spec)
local source=flag and window.flags[flag]
local name=tostring(source and source.Title or flag or"another setting")
if type(spec)=="table"and spec.Value~=nil and type(spec.Value)~="function"then return"Needs "..name..": "..tostring(spec.Value)end
if type(spec)=="table"and spec.Not then return"Turn off "..name.." first"end
return flag and("Turn on "..name.." first")or"Not available right now"
end
Base.depend(window,spec,function(ok)
if not row.Parent then return false end
if mode=="Hide"then
if card.Collapsed and row.Parent==card.frame then
card._hidden=card._hidden or{}
card._hidden[row]=ok or nil
row.Visible=false
else
row.Visible=ok
end
elseif ok then
if element._depLocked then element._depLocked=false element:Unlock()end
elseif not element.Locked or element._depLocked then
element._depLocked=true
element:Lock(reason())
end
end)
end
return element
end
function Base.flash(row,kind)
if not row or not row.Parent then return end
local flash=row:FindFirstChild("Flash")
if not flash then
flash=create("Frame",{
Name="Flash",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(-6,-2),
Size=UDim2.new(1,12,1,4),ZIndex=0,Parent=row,
})
corner(flash,6)
end
Theme.bind(flash,"BackgroundColor3",kind or"accent")
local token=(flash:GetAttribute("Token")or 0)+1
flash:SetAttribute("Token",token)
flash.BackgroundTransparency=0.78
task.delay(0.12,function()
if flash.Parent and flash:GetAttribute("Token")==token then Util.tween(flash,0.5,{BackgroundTransparency=1})end
end)
end
function Base.failed(element,title)
Base.flash(element.Row,"danger")
Sounds.Play("error")
if not title or not title.Parent then return end
element._errorToken=(element._errorToken or 0)+1
local token=element._errorToken
if not element._errorShown then
element._errorShown=true
element._titleBefore=tostring(element.Text or element.Title or title.Text)
Theme.bind(title,"TextColor3","danger")
end
title.Text="Error · see Settings › Info"
task.delay(2.2,function()
if element._errorToken~=token or not title.Parent then return end
element._errorShown=false
title.Text=element._titleBefore or tostring(element.Title or"")
Theme.bind(title,"TextColor3",element._risky and"danger"or"text")
end)
end
function Base.finish(element,cfg)
if cfg.Locked then element:Lock(cfg.LockedTitle or cfg.LockedReason)end
return element
end
return Base
end
__modules["elements/button"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
local STYLES={
Default={bg="input",bgT=0,text="text",edge="buttonEdge",edgeT=0,
hover={bg="hover",bgT=0,text="heading"}},
Primary={bg="accent",bgT=0,text="onAccent",edge="accent",edgeT=0,
hover={bg="accent",bgT=0.15,text="onAccent"}},
Soft={bg="accent",bgT=0.86,text="accent",edge="accent",edgeT=0.72,
hover={bg="accent",bgT=0.76,text="accent"}},
Outline={bg="hover",bgT=1,text="text",edge="buttonEdge",edgeT=0,
hover={bg="hover",bgT=0.4,text="heading"}},
Ghost={bg="hover",bgT=1,text="muted",edge="buttonEdge",edgeT=1,
hover={bg="hover",bgT=0,text="heading"}},
Danger={bg="danger",bgT=0.86,text="danger",edge="danger",edgeT=0.65,
hover={bg="danger",bgT=0.74,text="danger"}},
Link={bg="hover",bgT=1,text="accent",edge="accent",edgeT=1,
hover={bg="hover",bgT=1,text="heading"}},
}
local SIZES={Small={22,9,11},Default={28,10,13},Large={34,11,15}}
local ARROW=26
local ITEM=26
local function styleName(value)
value=tostring(value or"Default")
for name in pairs(STYLES)do if name:lower()==value:lower()then return name end end
return"Default"
end
local function entries(list)
local out={}
for _,option in ipairs(type(list)=="table"and list or{})do
if type(option)=="table"then
out[#out+1]={Title=tostring(option.Title or option[1]or""),Icon=option.Icon}
else
out[#out+1]={Title=tostring(option)}
end
end
return out
end
return function(card,cfg)
local window=card.window
local sizeName=tostring(cfg.Size or"Default")
local size=SIZES[sizeName:sub(1,1):upper()..sizeName:sub(2):lower()]or SIZES.Default
local buttonHeight,textSize,iconSize=size[1],size[2],size[3]
local height=cfg.Desc and buttonHeight+16 or buttonHeight
local title=cfg.Title~=nil and tostring(cfg.Title)or(cfg.Icon and""or"Button")
local row=create("Frame",{Name=title~=""and title or tostring(cfg.Icon),BackgroundTransparency=1,Size=UDim2.new(1,0,0,height),LayoutOrder=card:_order(),Parent=card.body})
local button=create("TextButton",{
Name="Button",Size=UDim2.new(1,0,0,buttonHeight),BorderSizePixel=0,Text="",
TextSize=textSize,Font=Enum.Font.Gotham,AutoButtonColor=false,Parent=row,
})
corner(button,6)
local outline=stroke(button)
local desc
if cfg.Desc then
desc=Util.label(row,tostring(cfg.Desc),9,{Position=UDim2.fromOffset(2,buttonHeight+2),Size=UDim2.new(1,-4,0,14)})
Theme.bind(desc,"TextColor3","muted")
end
local fill=create("Frame",{Name="Fill",BorderSizePixel=0,Size=UDim2.fromScale(0,1),BackgroundTransparency=1,ZIndex=1,Parent=button})
corner(fill,6)
local left=tostring(cfg.Align or""):lower()=="left"
local content=create("Frame",{
Name="Content",BackgroundTransparency=1,AnchorPoint=Vector2.new(left and 0 or 0.5,0.5),ZIndex=2,
Position=left and UDim2.new(0,10,0.5,0)or UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,Parent=button,
})
Util.list(content,6,Enum.FillDirection.Horizontal,left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)
local iconRight=tostring(cfg.IconSide or""):lower()=="right"
local icon=cfg.Icon and Icons.Get(cfg.Icon)and Icons.themed(content,cfg.Icon,iconSize,"text",{Name="ButtonIcon",LayoutOrder=iconRight and 3 or 1})or nil
local spinner=Icons.themed(content,"loader-circle",iconSize,"text",{Name="Spinner",LayoutOrder=0,Visible=false})
local textLabel=Util.label(content,title,textSize,{
Name="Text",Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2,Visible=title~="",
})
local selectedLabel
local rightUsed=0
local menu=cfg.Menu~=nil and entries(cfg.Menu)or nil
local arrow
if menu then
arrow=create("TextButton",{
Name="MenuArrow",Text="",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3,
AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(1,0),Size=UDim2.new(0,ARROW,1,0),Parent=button,
})
local split=create("Frame",{Name="Split",BorderSizePixel=0,Position=UDim2.new(0,0,0,6),Size=UDim2.new(0,1,1,-12),BackgroundTransparency=0.4,Parent=arrow})
Theme.bind(split,"BackgroundColor3","buttonEdge")
Icons.themed(arrow,"chevron-down",12,"text",{Name="Chevron",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,1,0.5,0)})
rightUsed=ARROW
if not left then content.Position=UDim2.new(0.5,-ARROW/2,0.5,0)end
if cfg.ShowSelected~=false then
selectedLabel=Util.label(content,"",textSize,{Name="Selected",Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,TextTruncate=Enum.TextTruncate.None,LayoutOrder=4,Visible=false})
end
end
local keyCap=create("Frame",{Name="Key",AnchorPoint=Vector2.new(1,0.5),Size=UDim2.fromOffset(20,math.min(16,buttonHeight-8)),BorderSizePixel=0,BackgroundTransparency=1,ZIndex=3,Visible=false,Parent=button})
corner(keyCap,4)
local keyStroke=stroke(keyCap,nil,0.3)
Theme.bind(keyStroke,"Color","buttonEdge")
local keyText=Util.label(keyCap,"",8,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamMedium,ZIndex=3})
local timer=Util.label(button,"",math.max(8,textSize-1),{Name="Timer",AnchorPoint=Vector2.new(1,0.5),Size=UDim2.fromOffset(40,buttonHeight),TextXAlignment=Enum.TextXAlignment.Right,ZIndex=3,Visible=false})
local badge=create("Frame",{Name="Badge",AnchorPoint=Vector2.new(1,0),Size=UDim2.fromOffset(16,13),BorderSizePixel=0,ZIndex=4,Visible=false,Parent=button})
corner(badge,6)
Theme.bind(badge,"BackgroundColor3","accent")
local badgeText=Util.label(badge,"",8,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=4})
Theme.bind(badgeText,"TextColor3","onAccent")
local element=Base.element(card,"Button",cfg,row,button,desc)
local paint
button:GetPropertyChangedSignal("Text"):Connect(function()
if button.Text==""then return end
textLabel.Text=button.Text
textLabel.Visible=true
button.Text=""
if element._errorShown then
task.delay(2.4,function()
if not element._errorShown and button.Parent then element:SetTitle(element.Text)if paint then paint(0)end end
end)
end
end)
button:GetPropertyChangedSignal("TextColor3"):Connect(function()
if element._errorShown then textLabel.TextColor3=button.TextColor3 elseif paint then paint(0)end
end)
element.Text=title
element.Style=styleName(cfg.Style)
local baseStyle=STYLES[element.Style]
local isToggle=cfg.Toggle==true
if isToggle then element.Value=cfg.Default==true end
local hovered,loading,cooling,holding=false,false,false,false
local busy=false
local function style()
if isToggle and element.Value then return STYLES[styleName(cfg.OnStyle or"Primary")]end
return baseStyle
end
local function textRole(set)
local current=style()
if cfg.Risky and(current==STYLES.Default or current==STYLES.Outline or current==STYLES.Ghost)then return"danger"end
return set.text
end
local function fillRole()
local current=style()
if current==STYLES.Primary then return"onAccent",0.75 end
if current==STYLES.Danger or cfg.Risky then return"danger",0.7 end
return"accent",0.78
end
function paint(duration)
local current=style()
local set=hovered and not(loading or cooling)and current.hover or current
local role=textRole(set)
Theme.tweenTo(button,"BackgroundColor3",set.bg,duration)
if duration>0 then Util.tween(button,duration,{BackgroundTransparency=set.bgT})else button.BackgroundTransparency=set.bgT end
Theme.tweenTo(outline,"Color",current.edge,duration)
outline.Transparency=current.edgeT
Theme.tweenTo(textLabel,"TextColor3",role,duration)
if icon then Theme.tweenTo(icon,"ImageColor3",role,duration)end
if spinner then Theme.tweenTo(spinner,"ImageColor3",role,duration)end
if selectedLabel then Theme.tweenTo(selectedLabel,"TextColor3",role,duration)selectedLabel.TextTransparency=0.45 end
if arrow then
local chevron=arrow:FindFirstChild("Chevron")
if chevron then Theme.tweenTo(chevron,"ImageColor3",role,duration)end
end
Theme.tweenTo(keyText,"TextColor3",element.KeyConflict and"warning"or role,duration)
keyText.TextTransparency=element.KeyConflict and 0 or 0.35
Theme.bind(keyStroke,"Color",element.KeyConflict and"warning"or"buttonEdge")
Theme.tweenTo(timer,"TextColor3",role,duration)
local dim=(loading or cooling)and 0.45 or 0
textLabel.TextTransparency=dim
if icon then icon.ImageTransparency=dim end
local tint,transparency=fillRole()
Theme.bind(fill,"BackgroundColor3",tint)
if fill.BackgroundTransparency<1 then fill.BackgroundTransparency=transparency end
end
local function fit()
local width=button.AbsoluteSize.X/(window.scale and window.scale.Scale or 1)
if width<=0 then return end
local reserved=20+(content.Position.X.Offset<0 and-content.Position.X.Offset*2 or 0)
for _,object in ipairs({icon,spinner})do
if object and object.Visible then reserved=reserved+iconSize+6 end
end
if selectedLabel and selectedLabel.Visible then reserved=reserved+Util.textWidth(selectedLabel.Text,textSize,Enum.Font.Gotham)+6 end
local room=math.max(0,math.floor(width-reserved))
local need=Util.textWidth(textLabel.Text,textSize,Enum.Font.Gotham)
if textLabel.Text~=""and need>room then
textLabel.AutomaticSize=Enum.AutomaticSize.None
textLabel.Size=UDim2.new(0,room,1,0)
textLabel.TextTruncate=Enum.TextTruncate.AtEnd
if cfg.Tooltip==nil then element._tooltip=textLabel.Text end
else
textLabel.AutomaticSize=Enum.AutomaticSize.X
textLabel.Size=UDim2.fromScale(0,1)
textLabel.TextTruncate=Enum.TextTruncate.None
if cfg.Tooltip==nil then element._tooltip=nil end
end
end
local function layoutRight()
local x=rightUsed
if keyCap.Visible then
keyCap.Position=UDim2.new(1,-(x+6),0.5,0)
x=x+6+keyCap.Size.X.Offset
end
timer.Position=UDim2.new(1,-(x+8),0.5,0)
if timer.Visible then x=x+8+math.max(26,Util.textWidth(timer.Text,timer.TextSize,Enum.Font.Gotham))end
badge.Position=UDim2.new(1,-(rightUsed+3),0,3)
if not left then content.Position=UDim2.new(0.5,-x/2,0.5,0)end
fit()
end
layoutRight()
button:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
row:GetPropertyChangedSignal("Size"):Connect(function()task.defer(fit)end)
textLabel:GetPropertyChangedSignal("Text"):Connect(function()task.defer(fit)end)
function element:SetTitle(text)
self.Text=tostring(text)
textLabel.Text=self.Text
textLabel.Visible=self.Text~=""
end
function element:SetIcon(name)if icon then Icons.Apply(icon,name)end end
function element:SetStyle(name)
self.Style=styleName(name)
baseStyle=STYLES[self.Style]
paint(0.12)
end
function element:SetBadge(text)
local shown=text~=nil and text~=false and tostring(text)~=""and tostring(text)~="0"
badge.Visible=shown
if shown then
badgeText.Text=tostring(text)
badge.Size=UDim2.fromOffset(math.max(13,Util.textWidth(badgeText.Text,8,Enum.Font.GothamBold)+8),13)
end
self.Badge=shown and tostring(text)or nil
end
element:SetBadge(cfg.Badge)
local spinConnection,doneToken=nil,0
function element:SetLoading(on,text)
loading=on==true
self.Loading=loading
if spinConnection then spinConnection:Disconnect()spinConnection=nil end
if spinner then
spinner.Rotation=0
Icons.Apply(spinner,"loader-circle")
spinner.Visible=loading
if loading then
spinConnection=window.maid:connect(Util.Services.RunService.Heartbeat,function(dt)
if not spinner.Parent then
if spinConnection then spinConnection:Disconnect()spinConnection=nil end
return
end
spinner.Rotation=(spinner.Rotation+(dt or 1/60)*360)%360
end)
end
end
if icon and not iconRight then icon.Visible=not loading end
textLabel.Text=loading and text and tostring(text)or(loading and cfg.LoadingText and tostring(cfg.LoadingText))or self.Text
textLabel.Visible=textLabel.Text~=""
paint(0.1)
end
local function showDone()
if cfg.Done==false or not spinner then return end
doneToken=doneToken+1
local token=doneToken
Icons.Apply(spinner,"check")
spinner.Rotation=0
spinner.Visible=true
if icon and not iconRight then icon.Visible=false end
task.delay(1.2,function()
if token~=doneToken or loading or not spinner.Parent then return end
spinner.Visible=false
Icons.Apply(spinner,"loader-circle")
if icon then icon.Visible=true end
end)
end
local coolToken=0
local cooldown=tonumber(cfg.Cooldown)or 0
local function endCooldown()
coolToken=coolToken+1
cooling=false
element.CoolingDown=false
timer.Visible=false
layoutRight()
fill.BackgroundTransparency=1
fill.Size=UDim2.fromScale(0,1)
paint(0.1)
end
local function startCooldown()
if cooldown<=0 then return end
coolToken=coolToken+1
local token=coolToken
cooling=true
element.CoolingDown=true
local _,transparency=fillRole()
fill.Size=UDim2.fromScale(1,1)
fill.BackgroundTransparency=transparency
Util.tween(fill,cooldown,{Size=UDim2.fromScale(0,1)},Enum.EasingStyle.Linear)
timer.Visible=true
timer.Text=string.format("%.1fs",cooldown)
layoutRight()
paint(0.1)
local finish=os.clock()+cooldown
task.spawn(function()
while token==coolToken and button.Parent do
local left=finish-os.clock()
if left<=0 then break end
timer.Text=left>=10 and string.format("%ds",math.ceil(left))or string.format("%.1fs",left)
task.wait(0.1)
end
if token==coolToken then endCooldown()end
end)
end
function element:SetCooldown(seconds)cooldown=tonumber(seconds)or 0 end
function element:ResetCooldown()if cooling then endCooldown()end end
local function run(...)
if busy or element.Locked then return end
busy=true
local args=table.pack(...)
local finished,ok=false,nil
task.spawn(function()
ok=element:_call(cfg.Callback,table.unpack(args,1,args.n))
finished=true
busy=false
if loading then
element:SetLoading(false)
if ok~=false then showDone()end
end
if ok~=false then startCooldown()end
end)
if not finished and cfg.Loading~=false then element:SetLoading(true)end
end
local function activate()
if element.Locked or loading or cooling or busy then return end
if isToggle then
element:Set(not element.Value)
elseif menu then
run(element.Selected)
else
run()
end
end
function element:Set(value,silent)
if not isToggle then return end
value=value==true
local changed=value~=self.Value
self.Value=value
if cfg.OnTitle then self:SetTitle(value and cfg.OnTitle or(cfg.Title or""))end
if cfg.OnIcon and icon then Icons.Apply(icon,value and cfg.OnIcon or cfg.Icon)end
paint(0.12)
if silent or not changed then
self:_fire(value,true)
else
self:_fire(value,false)
startCooldown()
end
end
function element:Get()return self.Value end
local holdTime=tonumber(cfg.Hold)or 0
local holdToken=0
local function cancelHold()
if not holding then return end
holding=false
holdToken=holdToken+1
Util.tween(fill,0.15,{Size=UDim2.fromScale(0,1)})
task.delay(0.16,function()if not holding and not cooling then fill.BackgroundTransparency=1 end end)
end
local function startHold()
if element.Locked or loading or cooling or busy or holding then return end
holding=true
holdToken=holdToken+1
local token=holdToken
local _,transparency=fillRole()
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundTransparency=transparency
Util.tween(fill,holdTime,{Size=UDim2.fromScale(1,1)},Enum.EasingStyle.Linear)
task.delay(holdTime,function()
if token~=holdToken or not holding or not button.Parent then return end
holding=false
fill.BackgroundTransparency=1
fill.Size=UDim2.fromScale(0,1)
require("sounds").Play("click")
activate()
end)
end
element.Hold=holdTime>0 and holdTime or nil
local bindable=cfg.Bindable==true or cfg.Bind~=nil
function element:SetBind(key)
key=Util.toKey(key)
self.BindKey=key
window:_bind(self,key)
keyCap.Visible=key~=nil
if key then
keyText.Text=Util.keyName(key)
keyCap.Size=UDim2.fromOffset(math.max(16,Util.textWidth(keyText.Text,8,Enum.Font.GothamMedium)+10),keyCap.Size.Y.Offset)
end
layoutRight()
end
function element:_onBind()
if holdTime>0 then startHold()else activate()end
end
function element:_onRelease()if holdTime>0 then cancelHold()end end
function element:_onConflict()paint(0)end
if bindable then
element:SetBind(cfg.Bind)
button.MouseButton2Click:Connect(function()
if element.Locked then return end
keyCap.Visible,keyText.Text=true,"..."
keyCap.Size=UDim2.fromOffset(24,keyCap.Size.Y.Offset)
layoutRight()
window._capture=function(key)
if key==Enum.KeyCode.Escape or key==window.key then element:SetBind(element.BindKey)
elseif key==Enum.KeyCode.Backspace then element:SetBind(nil)
else element:SetBind(key)end
end
end)
end
local popup
function element:Select(option,silent)
option=option~=nil and tostring(option)or nil
local known=false
for _,entry in ipairs(menu or{})do if entry.Title==option then known=true end end
if not known then return end
self.Selected=option
if selectedLabel then
selectedLabel.Text=option
selectedLabel.Visible=true
end
if not silent then run(option)end
end
function element:SetOptions(list)
if not menu then return end
menu=entries(list)
local still=false
for _,entry in ipairs(menu)do if entry.Title==self.Selected then still=true end end
if not still then
self.Selected=nil
if menu[1]then self:Select(menu[1].Title,true)elseif selectedLabel then selectedLabel.Visible=false end
end
end
local function closeMenu()
if popup then popup:Destroy()popup=nil end
end
local function openMenu()
closeMenu()
local position,buttonSize=Util.screenPos(button),button.AbsoluteSize
local viewport=Util.viewport()
local scale=window.scale and window.scale.Scale or 1
local width=math.max(buttonSize.X/scale,140)
local total=#menu*ITEM+8
local roomBelow=viewport.Y-8-(position.Y+buttonSize.Y+4)
local below=roomBelow>=total*scale or roomBelow>=position.Y
popup=create("Frame",{
Name="ButtonMenu",BorderSizePixel=0,ZIndex=260,Size=UDim2.fromOffset(width,total),
Position=UDim2.fromOffset(math.clamp(position.X+buttonSize.X-width*scale,8,math.max(8,viewport.X-width*scale-8)),
below and position.Y+buttonSize.Y+4 or position.Y-4-total*scale),
Parent=window.gui,
})
create("UIScale",{Scale=scale,Parent=popup})
Theme.bind(popup,"BackgroundColor3","input")
corner(popup,6)
Theme.bind(stroke(popup),"Color","buttonEdge")
Util.padding(popup,4,4,4,4)
Util.list(popup,0)
for index,entry in ipairs(menu)do
local item=create("TextButton",{
Name=entry.Title,Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundTransparency=1,
Size=UDim2.new(1,0,0,ITEM),LayoutOrder=index,ZIndex=261,Parent=popup,
})
Theme.bind(item,"BackgroundColor3","hover")
corner(item,5)
local x=8
if entry.Icon and Icons.Get(entry.Icon)then
Icons.themed(item,entry.Icon,12,"muted",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),ZIndex=262})
x=26
end
local text=Util.label(item,entry.Title,10,{Position=UDim2.fromOffset(x,0),Size=UDim2.new(1,-x-20,1,0),ZIndex=262})
local chosen=entry.Title==element.Selected
Theme.bind(text,"TextColor3",chosen and"heading"or"text")
if chosen then
local dot=create("Frame",{Name="Check",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,ZIndex=262,Parent=item})
Theme.bind(dot,"BackgroundColor3","accent")
corner(dot,3)
end
item.MouseEnter:Connect(function()Util.tween(item,0.08,{BackgroundTransparency=0})end)
item.MouseLeave:Connect(function()Util.tween(item,0.08,{BackgroundTransparency=1})end)
item.Activated:Connect(function()
window:_closePopup()
require("sounds").Play("click")
if element.Locked or loading or cooling or busy then return end
element:Select(entry.Title)
end)
end
window:_openPopup(popup,arrow,closeMenu)
end
if menu then
local first=cfg.Selected~=nil and tostring(cfg.Selected)or(menu[1]and menu[1].Title)
element:Select(first,true)
arrow.Activated:Connect(function()
if element.Locked then return end
if popup then window:_closePopup()else openMenu()end
end)
end
if cfg.Flag then
function element:_save()
return{Value=isToggle and self.Value or nil,Selected=self.Selected,Bind=self.BindKey and Util.keyName(self.BindKey)or nil}
end
function element:_load(data)
if type(data)~="table"then data={Value=data}end
if bindable and data.Bind~=nil then self:SetBind(data.Bind)end
if menu and data.Selected~=nil then self:Select(data.Selected,true)end
if isToggle and data.Value~=nil then self:Set(data.Value==true)end
end
end
paint(0)
if isToggle then element:_fire(element.Value,true)end
function element:Fire()activate()end
button.MouseEnter:Connect(function()hovered=true paint(0.12)end)
button.MouseLeave:Connect(function()
hovered=false
paint(0.12)
cancelHold()
end)
if holdTime>0 then
button.InputBegan:Connect(function(input)if Util.isPress(input)then startHold()end end)
button.InputEnded:Connect(function(input)if Util.isPress(input)then cancelHold()end end)
end
local armed=0
button.Activated:Connect(function()
if holdTime>0 then return end
require("sounds").Play("click")
if element.Locked or loading or cooling or busy then return end
if cfg.Confirm then
if armed==0 then
armed=armed+1
local token=armed
textLabel.Text=type(cfg.Confirm)=="string"and cfg.Confirm or"Click again to confirm"
textLabel.Visible=true
Theme.tweenTo(outline,"Color","accent",0.1)
outline.Transparency=0
task.delay(2,function()
if armed==token and button.Parent then
armed=0
element:SetTitle(element.Text)
paint(0.1)
end
end)
return
end
armed=0
element:SetTitle(element.Text)
paint(0.1)
end
activate()
end)
return Base.finish(element,cfg)
end
end
__modules["elements/checkbox"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 28,{button=true,noIcon=true})
local box=create("Frame",{Name="Box",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0,cfg.Desc and 12 or 14),Size=UDim2.fromOffset(16,16),BorderSizePixel=0,Parent=row})
corner(box,4)
local edge=stroke(box)
local tick=Icons.themed(box,"check",12,"onAccent",{Name="Tick",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
title.Position=UDim2.new(0,26,0,title.Position.Y.Offset)
title.Size=UDim2.new(1,-26-(cfg.Help and 16 or 0),0,title.Size.Y.Offset)
if desc then desc.Position=UDim2.fromOffset(26,23)desc.Size=UDim2.new(1,-26,0,14)end
local element=Base.element(card,"Checkbox",cfg,row,title,desc)
element.Value=cfg.Default==true
local hovered=false
local function render(animate)
local on=element.Value
local duration=animate and 0.12 or nil
Theme.tweenTo(box,"BackgroundColor3",on and"accent"or(hovered and"hover"or"input"),duration)
Theme.tweenTo(edge,"Color",on and"accent"or"buttonEdge",duration)
if tick then tick.Visible=on end
end
function element:Set(value,silent)
value=value==true
local changed=value~=self.Value
self.Value=value
render(true)
self:_fire(value,silent or not changed)
end
function element:Get()return self.Value end
row.Activated:Connect(function()if not element.Locked then element:Set(not element.Value)end end)
row.MouseEnter:Connect(function()hovered=true render(true)Theme.tweenTo(title,"TextColor3",cfg.Risky and"danger"or"heading",0.12)end)
row.MouseLeave:Connect(function()hovered=false render(true)Theme.tweenTo(title,"TextColor3",cfg.Risky and"danger"or"text",0.12)end)
render(false)
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/code"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local KEYWORDS={}
for word in("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%a+")do KEYWORDS[word]=true end
local GLOBALS={}
for word in("game workspace script task math string table print warn pcall require loadstring getgenv Instance Vector3 Vector2 CFrame UDim2 Color3 Enum"):gmatch("%a+")do GLOBALS[word]=true end
local ROLES={keyword="codeKeyword",string="codeString",number="codeNumber",comment="codeComment",global="codeGlobal",call="codeCall"}
local function escape(text)return(text:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"))end
local function paint(kind,text)return'<font color="#'..Util.toHex(Theme.get(ROLES[kind]))..'">'..escape(text).."</font>"end
local function highlight(source)
local out,i,n={},1,#source
while i<=n do
local c=source:sub(i,i)
if source:sub(i,i+1)=="--"then
local long=source:match("^%-%-%[(=*)%[",i)
local stop
if long then stop=select(2,source:find("%]"..long.."%]",i))end
stop=stop or(source:find("\n",i)or n+1)-1
out[#out+1]=paint("comment",source:sub(i,stop))
i=stop+1
elseif c=='"'or c=="'"then
local j=i+1
while j<=n do
local d=source:sub(j,j)
if d=="\\"then j=j+2 elseif d==c or d=="\n"then break else j=j+1 end
end
out[#out+1]=paint("string",source:sub(i,j))
i=j+1
elseif source:match("^%[=*%[",i)then
local eq=source:match("^%[(=*)%[",i)
local stop=select(2,source:find("%]"..eq.."%]",i))or n
out[#out+1]=paint("string",source:sub(i,stop))
i=stop+1
elseif c:match("%d")then
local number=source:match("^0[xX]%x+",i)or source:match("^%d+%.?%d*[eE][%-+]?%d+",i)or source:match("^%d+%.?%d*",i)
out[#out+1]=paint("number",number)
i=i+#number
elseif c:match("[%a_]")then
local word=source:match("^[%w_]+",i)
local after=source:match("^%s*(.)",i+#word)
if KEYWORDS[word]then out[#out+1]=paint("keyword",word)
elseif GLOBALS[word]then out[#out+1]=paint("global",word)
elseif after=="("then out[#out+1]=paint("call",word)
else out[#out+1]=escape(word)end
i=i+#word
else
out[#out+1]=escape(c)
i=i+1
end
end
return table.concat(out)
end
return function(card,cfg)
local window=card.window
local maxHeight=tonumber(cfg.MaxHeight)or 200
local holder=create("Frame",{Name=tostring(cfg.Title or"Code"),Size=UDim2.new(1,0,0,60),BorderSizePixel=0,LayoutOrder=card:_order(),Parent=card.body})
Theme.bind(holder,"BackgroundColor3","base")
corner(holder,7)
Theme.bind(stroke(holder),"Color","line")
local head=create("Frame",{Name="Head",BackgroundTransparency=1,Size=UDim2.new(1,0,0,26),Parent=holder})
Icons.themed(head,"code",12,"muted",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,10,0.5,0)})
local title=label(head,tostring(cfg.Title or"Code"),10,{Name="Title",Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-90,1,0),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3","text")
local line=create("Frame",{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,Parent=holder})
Theme.bind(line,"BackgroundColor3","line")
local scroller=create("ScrollingFrame",{
Name="Body",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,27),Size=UDim2.new(1,0,1,-27),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.XY,ScrollBarThickness=3,Parent=holder,
})
Theme.bind(scroller,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(scroller)
local text=create("TextLabel",{
Name="Code",BackgroundTransparency=1,Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(0,0),AutomaticSize=Enum.AutomaticSize.XY,
Font=Enum.Font.Code,TextSize=11,RichText=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
TextWrapped=false,Text="",Parent=scroller,
})
Theme.bind(text,"TextColor3","heading")
create("UIPadding",{PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,10),Parent=text})
local element=Base.element(card,"Code",{},holder,title,nil)
local function fit()
local lines=select(2,(element.Value or""):gsub("\n","\n"))+1
holder.Size=UDim2.new(1,0,0,math.min(maxHeight,27+18+lines*14))
end
function element:Set(code)
self.Value=tostring(code or"")
text.Text=cfg.Highlight==false and self.Value:gsub("<","&lt;")or highlight(self.Value)
fit()
end
function element:Get()return self.Value end
if cfg.Copy~=false then
local copy=create("TextButton",{
Name="Copy",Text="",AutoButtonColor=false,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,-6,0.5,0),Size=UDim2.fromOffset(52,18),Parent=head,
})
Theme.bind(copy,"BackgroundColor3","input")
corner(copy,5)
Theme.bind(stroke(copy),"Color","buttonEdge")
local copyText=label(copy,"Copy",9,{Position=UDim2.fromOffset(20,0),Size=UDim2.new(1,-22,1,0),Font=Enum.Font.GothamMedium})
Theme.bind(copyText,"TextColor3","text")
local copyIcon=Icons.themed(copy,"copy",10,"text",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,7,0.5,0)})
copy.Activated:Connect(function()
local clipboard=setclipboard or toclipboard
local ok=type(clipboard)=="function"and pcall(clipboard,element.Value)
copyText.Text=ok and"Copied"or"Failed"
if copyIcon then Icons.Apply(copyIcon,ok and"check"or"x")end
if ok and cfg.OnCopy then window:_safe("Code",cfg.OnCopy)end
task.delay(1.4,function()
if copy.Parent then copyText.Text="Copy"if copyIcon then Icons.Apply(copyIcon,"copy")end end
end)
end)
end
element:Set(cfg.Code or"")
Theme.onChange(function()if holder.Parent then element:Set(element.Value)end end)
return element
end
end
__modules["elements/colorpicker"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
local HUE=ColorSequence.new({
ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(1/6,Color3.fromHSV(1/6,1,1)),
ColorSequenceKeypoint.new(2/6,Color3.fromHSV(2/6,1,1)),ColorSequenceKeypoint.new(3/6,Color3.fromHSV(3/6,1,1)),
ColorSequenceKeypoint.new(4/6,Color3.fromHSV(4/6,1,1)),ColorSequenceKeypoint.new(5/6,Color3.fromHSV(5/6,1,1)),
ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)),
})
return function(card,cfg)
local window=card.window
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 30,{right=60,button=true})
local swatch=create("TextButton",{
Name="Swatch",Text="",AutoButtonColor=false,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(34,18),Parent=row,
})
corner(swatch,5)
Theme.bind(stroke(swatch,nil,0.2),"Color","buttonEdge")
local panel=create("Frame",{
Name="Picker",BackgroundTransparency=1,Size=UDim2.new(1,0,0,158),LayoutOrder=row.LayoutOrder+1,
Visible=false,Parent=card.body,
})
local square=create("TextButton",{
Name="Square",Text="",AutoButtonColor=false,BorderSizePixel=0,Position=UDim2.fromOffset(0,4),
Size=UDim2.new(1,-104,0,104),Parent=panel,
})
corner(square,6)
local white=create("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),Parent=square})
corner(white,6)
create("UIGradient",{Transparency=NumberSequence.new(0,1),Parent=white})
local black=create("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),Parent=square})
corner(black,6)
create("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0),Parent=black})
local cursor=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(8,8),BackgroundTransparency=1,ZIndex=3,Parent=square})
corner(cursor,4)
stroke(cursor,Color3.new(1,1,1),0,1.5)
local hueBar=create("TextButton",{
Name="Hue",Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),
Position=UDim2.fromOffset(0,116),Size=UDim2.new(1,-104,0,10),Parent=panel,
})
corner(hueBar,5)
create("UIGradient",{Color=HUE,Parent=hueBar})
local hueCursor=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(4,14),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3,Parent=hueBar})
corner(hueCursor,2)
local alphaMode=cfg.Alpha==true or tonumber(cfg.Transparency)~=nil
local alphaBar,alphaCursor
if alphaMode then
local backing=create("Frame",{Name="AlphaBacking",BorderSizePixel=0,Position=UDim2.fromOffset(0,134),Size=UDim2.new(1,-104,0,10),Parent=panel})
Theme.bind(backing,"BackgroundColor3","input")
corner(backing,5)
local light=create("Frame",{BorderSizePixel=0,Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,0.5),BackgroundColor3=Color3.fromRGB(205,205,210),BackgroundTransparency=0.55,Parent=backing})
corner(light,5)
alphaBar=create("TextButton",{Name="Alpha",Text="",AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Parent=backing})
corner(alphaBar,5)
create("UIGradient",{Transparency=NumberSequence.new(0,1),Parent=alphaBar})
Theme.bind(stroke(backing,nil,0.3),"Color","buttonEdge")
alphaCursor=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(4,14),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3,Parent=backing})
corner(alphaCursor,2)
Theme.bind(stroke(alphaCursor,nil,0.2),"Color","base")
end
local side=create("Frame",{Name="Side",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,4),Size=UDim2.fromOffset(92,150),Parent=panel})
local preview=create("Frame",{Size=UDim2.new(1,0,0,26),BorderSizePixel=0,Parent=side})
corner(preview,6)
Theme.bind(stroke(preview,nil,0.2),"Color","buttonEdge")
local hex=create("TextBox",{
Name="Hex",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,24),BorderSizePixel=0,Text="",
TextSize=10,Font=Enum.Font.GothamMedium,ClearTextOnFocus=false,Parent=side,
})
Theme.bind(hex,"BackgroundColor3","input")
Theme.bind(hex,"TextColor3","text")
corner(hex,6)
Theme.bind(stroke(hex),"Color","buttonEdge")
local random=create("TextButton",{
Name="Random",Position=UDim2.fromOffset(0,62),Size=UDim2.new(1,0,0,24),BorderSizePixel=0,
Text="Random",TextSize=10,Font=Enum.Font.Gotham,AutoButtonColor=false,Parent=side,
})
Theme.bind(random,"BackgroundColor3","input")
Theme.bind(random,"TextColor3","text")
corner(random,6)
Theme.bind(stroke(random),"Color","buttonEdge")
local rainbow=create("TextButton",{
Name="Rainbow",Position=UDim2.fromOffset(0,92),Size=UDim2.new(1,0,0,24),BorderSizePixel=0,
Text="Rainbow",TextSize=10,Font=Enum.Font.Gotham,AutoButtonColor=false,Parent=side,
})
Theme.bind(rainbow,"BackgroundColor3","input")
Theme.bind(rainbow,"TextColor3","text")
corner(rainbow,6)
local rainbowEdge=stroke(rainbow)
Theme.bind(rainbowEdge,"Color","buttonEdge")
local done=create("TextButton",{
Name="Done",Position=UDim2.fromOffset(0,122),Size=UDim2.new(1,0,0,24),BorderSizePixel=0,
Text=cfg.Apply and"Apply"or"Done",TextSize=10,Font=Enum.Font.GothamMedium,AutoButtonColor=false,Parent=side,
})
Theme.bind(done,"BackgroundColor3","accentDeep")
Theme.bind(done,"TextColor3","accent")
corner(done,6)
Theme.bind(stroke(done,nil,0.45),"Color","accent")
local element=Base.element(card,"ColorPicker",cfg,row,title,desc)
local h,s,v=0,0,1
local alpha=math.clamp(tonumber(cfg.Transparency)or 0,0,1)
element.Transparency=alpha
local function render()
local color=Color3.fromHSV(h,s,v)
swatch.BackgroundColor3,preview.BackgroundColor3=color,color
square.BackgroundColor3=Color3.fromHSV(h,1,1)
cursor.Position=UDim2.fromScale(s,1-v)
hueCursor.Position=UDim2.fromScale(h,0.5)
hex.Text="#"..Util.toHex(color)
if alphaMode then
alphaBar.BackgroundColor3=color
alphaCursor.Position=UDim2.fromScale(alpha,0.5)
preview.BackgroundTransparency=alpha
swatch.BackgroundTransparency=alpha*0.85
end
end
local applyMode=cfg.Apply==true
local function commit(silent,force)
local color=Color3.fromHSV(h,s,v)
if applyMode and not force and panel.Visible and not silent then render()swatch.BackgroundColor3=element.Value or color return end
local changed=color~=element.Value or alpha~=element.Transparency
element.Value=color
element.Transparency=alpha
render()
if alphaMode then element:_fire(color,silent or not changed,alpha)else element:_fire(color,silent or not changed)end
end
function element:Set(color,silent)
if type(color)=="string"then color=Util.fromHex(color)end
if typeof(color)~="Color3"then return end
h,s,v=color:ToHSV()
commit(silent,true)
end
function element:Get()return self.Value,self.Transparency end
function element:SetTransparency(value,silent)
alpha=math.clamp(tonumber(value)or 0,0,1)
commit(silent,true)
end
function element:_save()
if self.Rainbow or(alphaMode and self.Transparency>0)then
return{Color=Util.toHex(self.Value),Rainbow=self.Rainbow or nil,Alpha=alphaMode and self.Transparency or nil}
end
return Util.toHex(self.Value)
end
function element:_load(data)
if type(data)=="table"then
if alphaMode then alpha=math.clamp(tonumber(data.Alpha)or 0,0,1)end
self:Set(data.Color)
self:SetRainbow(data.Rainbow==true)
else
if alphaMode then alpha=0 end
self:SetRainbow(false)
self:Set(data)
end
end
local function revert()
if applyMode and element.Value then h,s,v=element.Value:ToHSV()render()end
end
function element:SetOpen(open)
if not open then revert()end
panel.Visible=open==true
end
element.Rainbow=false
local rainbowConnection
local function renderRainbow()
Theme.tweenTo(rainbow,"BackgroundColor3",element.Rainbow and"accentDeep"or"input",0.1)
Theme.tweenTo(rainbow,"TextColor3",element.Rainbow and"accent"or"text",0.1)
Theme.tweenTo(rainbowEdge,"Color",element.Rainbow and"accent"or"buttonEdge",0.1)
end
function element:SetRainbow(on)
on=on==true
if on==self.Rainbow then return end
self.Rainbow=on
if rainbowConnection then rainbowConnection:Disconnect()rainbowConnection=nil end
if on then
local period=math.max(0.5,tonumber(cfg.RainbowSpeed)or 5)
local last=0
rainbowConnection=window.maid:connect(Util.Services.RunService.Heartbeat,function()
local now=os.clock()
if now-last<0.05 then return end
last=now
h=(now/period)%1
if s<0.05 then s=0.75 end
commit(false,true)
end)
end
renderRainbow()
end
local function drag(target,apply)
target.InputBegan:Connect(function(input)
if not Util.isPress(input)or element.Locked then return end
local function move(point)
local p,size=Util.screenPos(target),target.AbsoluteSize
if size.X<=0 or size.Y<=0 then return end
apply(math.clamp((point.X-p.X)/size.X,0,1),math.clamp((point.Y-p.Y)/size.Y,0,1))
commit()
end
move(Util.pointer(input))
window:_beginDrag(input,move)
end)
end
drag(square,function(x,y)s,v=x,1-y end)
drag(hueBar,function(x)h=math.min(x,0.999)end)
if alphaBar then drag(alphaBar,function(x)alpha=math.floor(x*100+0.5)/100 end)end
hex.FocusLost:Connect(function()
local color=Util.fromHex(hex.Text)
if color then h,s,v=color:ToHSV()commit()else render()end
end)
random.Activated:Connect(function()if not element.Locked then h,s,v=math.random(),0.45+math.random()*0.5,0.6+math.random()*0.4 commit()end end)
rainbow.Activated:Connect(function()if not element.Locked then element:SetRainbow(not element.Rainbow)end end)
done.Activated:Connect(function()
if applyMode then commit(false,true)end
panel.Visible=false
end)
local function toggleOpen()if not element.Locked then element:SetOpen(not panel.Visible)end end
row.Activated:Connect(toggleOpen)
swatch.Activated:Connect(toggleOpen)
local default=cfg.Default
if type(default)=="string"then default=Util.fromHex(default)end
element:Set(typeof(default)=="Color3"and default or Color3.new(1,1,1),true)
renderRainbow()
if cfg.Rainbow then element:SetRainbow(true)end
return Base.finish(element,cfg)
end
end
__modules["elements/console"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local LEVELS={info="text",success="success",warning="warning",warn="warning",error="danger",danger="danger",debug="muted"}
local function escape(text)return(tostring(text):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"))end
return function(card,cfg)
local maxLines=math.max(1,math.floor(tonumber(cfg.MaxLines)or 200))
local height=tonumber(cfg.Height)or 150
local holder=create("Frame",{Name=tostring(cfg.Title or"Console"),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,LayoutOrder=card:_order(),Parent=card.body})
Theme.bind(holder,"BackgroundColor3","base")
corner(holder,7)
Theme.bind(stroke(holder),"Color","line")
local head=create("Frame",{Name="Head",BackgroundTransparency=1,Size=UDim2.new(1,0,0,26),Parent=holder})
Icons.themed(head,cfg.Icon or"terminal",12,"muted",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,10,0.5,0)})
local title=label(head,tostring(cfg.Title or"Console"),10,{Name="Title",Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-150,1,0),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3","text")
local line=create("Frame",{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,Parent=holder})
Theme.bind(line,"BackgroundColor3","line")
local scroller=create("ScrollingFrame",{
Name="Lines",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,27),Size=UDim2.new(1,0,1,-27),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,
Parent=holder,
})
Theme.bind(scroller,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(scroller)
local list=create("Frame",{Name="List",BackgroundTransparency=1,Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=scroller})
Util.list(list,1)
Util.padding(list,0,0,0,8)
Util.fitCanvas(scroller,list)
local empty=label(scroller,cfg.Empty or"Nothing logged yet",10,{Name="Empty",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center})
Theme.bind(empty,"TextColor3","muted")
local element=Base.element(card,"Console",{},holder,title,nil)
element.Lines={}
element.Follow=cfg.Follow~=false
local order=0
local buttons={}
local function headButton(name,icon,tip,index,callback)
local button=create("TextButton",{
Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,-6-(index-1)*24,0.5,0),Size=UDim2.fromOffset(20,20),Parent=head,
})
corner(button,5)
Theme.bind(button,"BackgroundColor3","input")
local image=Icons.themed(button,icon,12,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
button.MouseEnter:Connect(function()
Util.tween(button,0.1,{BackgroundTransparency=0})
card.window:_tip(tip)
end)
button.MouseLeave:Connect(function()
Util.tween(button,0.1,{BackgroundTransparency=1})
card.window:_hideTip()
end)
button.Activated:Connect(callback)
buttons[name]={button=button,icon=image}
return button
end
local autoScrolling=false
local function scrollToEnd()
if not scroller.Parent then return end
autoScrolling=true
local content=math.max(scroller.AbsoluteCanvasSize.Y,list.AbsoluteSize.Y+6)
scroller.CanvasPosition=Vector2.new(0,math.max(0,content-scroller.AbsoluteWindowSize.Y))
autoScrolling=false
end
scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()if element.Follow then scrollToEnd()end end)
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()if element.Follow then scrollToEnd()end end)
local function renderFollow()
local entry=buttons.Follow
if entry and entry.icon then Theme.bind(entry.icon,"ImageColor3",element.Follow and"accent"or"muted")end
end
function element:SetFollow(on)
self.Follow=on~=false
renderFollow()
if self.Follow then scrollToEnd()end
end
scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
if autoScrolling then return end
local bottom=scroller.AbsoluteCanvasSize.Y-scroller.AbsoluteWindowSize.Y
if bottom<=0 then return end
local atEnd=scroller.CanvasPosition.Y>=bottom-4
if atEnd~=element.Follow then element.Follow=atEnd renderFollow()end
end)
function element:Append(text,level)
level=LEVELS[tostring(level or"info"):lower()]and tostring(level or"info"):lower()or"info"
text=tostring(text==nil and""or text)
local stamp=cfg.Time~=false and os.date("%H:%M:%S")or nil
order=order+1
local entry={text=text,level=level,time=stamp}
table.insert(self.Lines,entry)
local row=label(list,"",10,{
Name="Line",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,RichText=true,Font=Enum.Font.Code,LayoutOrder=order,
TextYAlignment=Enum.TextYAlignment.Top,
})
local function paint()
local prefix=stamp and('<font color="#'..Util.toHex(Theme.get("muted"))..'">'..stamp.."</font>  ")or""
row.Text=prefix..escape(text)
end
paint()
entry.label,entry.paint=row,paint
Theme.bind(row,"TextColor3",LEVELS[level])
empty.Visible=false
while#self.Lines>maxLines do
local old=table.remove(self.Lines,1)
if old.label then old.label:Destroy()end
end
if self.Follow then task.defer(scrollToEnd)end
return entry
end
function element:Print(...)
local parts=table.pack(...)
for index=1,parts.n do parts[index]=tostring(parts[index])end
return self:Append(table.concat(parts," ",1,parts.n))
end
function element:Log(text,level)return self:Append(text,level)end
function element:Clear()
for _,entry in ipairs(self.Lines)do if entry.label then entry.label:Destroy()end end
self.Lines={}
empty.Visible=true
end
function element:GetText()
local out={}
for _,entry in ipairs(self.Lines)do
out[#out+1]=(entry.time and("["..entry.time.."] ")or"")..(entry.level~="info"and(entry.level:upper()..": ")or"")..entry.text
end
return table.concat(out,"\n")
end
function element:SetTitle(text)title.Text=tostring(text)end
function element:Get()return self:GetText()end
if cfg.Copy~=false then
headButton("Copy","copy","Copy log",1,function()
local clipboard=setclipboard or toclipboard
local ok=type(clipboard)=="function"and pcall(clipboard,element:GetText())
local entry=buttons.Copy
if entry.icon then
Icons.Apply(entry.icon,ok and"check"or"x")
task.delay(1.2,function()if entry.icon.Parent then Icons.Apply(entry.icon,"copy")end end)
end
end)
end
headButton("Clear","trash-2","Clear",cfg.Copy~=false and 2 or 1,function()element:Clear()end)
headButton("Follow","arrow-down-to-line","Follow new lines",cfg.Copy~=false and 3 or 2,function()element:SetFollow(not element.Follow)end)
renderFollow()
Theme.onChange(function()
if not holder.Parent then return end
for _,entry in ipairs(element.Lines)do if entry.paint then entry.paint()end end
end)
for _,item in ipairs(cfg.Lines or{})do
if type(item)=="table"then element:Append(item[1]or item.Text,item[2]or item.Level)else element:Append(item)end
end
return element
end
end
__modules["elements/divider"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create=Util.create
return function(card)
local holder=create("Frame",{Name="Divider",BackgroundTransparency=1,Size=UDim2.new(1,0,0,7),LayoutOrder=card:_order(),Parent=card.body})
local line=create("Frame",{Position=UDim2.fromOffset(0,3),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundTransparency=0.3,Parent=holder})
Theme.bind(line,"BackgroundColor3","line")
return Base.element(card,"Divider",{},holder,nil,nil)
end
end
__modules["elements/dropdown"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local ITEM,ITEM_DESC,MAX_HEIGHT,SEARCH,CHUNK=24,34,176,28,60
return function(card,cfg)
local window=card.window
local multi=cfg.Multi==true
local options,info={},{}
local function setOptions(list)
options,info={},{}
list=list or{}
local isArray=#list>0 or next(list)==nil
if isArray then
for _,option in ipairs(list)do
local entry=type(option)=="table"and option or{Title=option}
local key=tostring(entry.Value or entry.Title or entry.Name or entry[1]or"")
entry.Title=tostring(entry.Title or entry.Name or entry[1]or key)
if not info[key]then options[#options+1]=key end
info[key]=entry
end
else
for key,value in pairs(list)do
local entry=type(value)=="table"and value or{Title=tostring(value)}
entry.Title=tostring(entry.Title or key)
key=tostring(key)
options[#options+1]=key
info[key]=entry
end
table.sort(options,function(a,b)return info[a].Title:lower()<info[b].Title:lower()end)
end
end
setOptions(cfg.Options or cfg.Values)
local function titleOf(key)return info[key]and info[key].Title or tostring(key)end
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 30,{right=160})
title.Size=UDim2.new(0.55,-8-title.Position.X.Offset,0,title.Size.Y.Offset)
if desc then desc.Size=UDim2.new(0.55,-8-desc.Position.X.Offset,0,14)end
local button=create("TextButton",{
Name="Select",Text="",AutoButtonColor=false,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),Size=UDim2.new(0.45,0,0,24),Parent=row,
})
Theme.bind(button,"BackgroundColor3","input")
corner(button,6)
Theme.bind(stroke(button),"Color","buttonEdge")
create("UISizeConstraint",{MaxSize=Vector2.new(170,24),Parent=button})
local valueIcon=create("ImageLabel",{Name="ValueIcon",BackgroundTransparency=1,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),Size=UDim2.fromOffset(12,12),Visible=false,Parent=button})
local valueLabel=label(button,"",10,{Position=UDim2.fromOffset(9,0),Size=UDim2.new(1,-28,1,0)})
Theme.bind(valueLabel,"TextColor3","text")
local arrow=create("Frame",{Name="Chevron",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,1),Size=UDim2.fromOffset(10,6),Parent=button})
local arrowBars={}
for index,rotation in ipairs({45,-45})do
local bar=create("Frame",{
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(index==1 and 3 or 7,3),Size=UDim2.fromOffset(6,1.5),
Rotation=rotation,BorderSizePixel=0,Parent=arrow,
})
Theme.bind(bar,"BackgroundColor3","muted")
arrowBars[index]=bar
end
local function tintArrow(role)for _,bar in ipairs(arrowBars)do Theme.tweenTo(bar,"BackgroundColor3",role,0.1)end end
local element=Base.element(card,"Dropdown",cfg,row,title,desc)
element.Options=options
local function chosen(option)
if multi then return table.find(element.Value,option)~=nil end
return element.Value==option
end
local function applyVisual(image,entry,role)
if entry.Image then
if not Icons.Apply(image,entry.Image)then image.Image=tostring(entry.Image)end
Theme.bind(image,"ImageColor3",Color3.new(1,1,1))
return true
elseif entry.Icon and Icons.Apply(image,entry.Icon)then
Theme.bind(image,"ImageColor3",role)
return true
end
return false
end
local function render()
local text
if multi then
local titles={}
for _,key in ipairs(element.Value)do titles[#titles+1]=titleOf(key)end
text=#titles>0 and table.concat(titles,", ")or"None"
else
text=element.Value and titleOf(element.Value)or"None"
end
valueLabel.Text=text
local entry=not multi and element.Value and info[element.Value]
local hasVisual=entry and applyVisual(valueIcon,entry,"text")or false
valueIcon.Visible=hasVisual
valueLabel.Position=UDim2.fromOffset(hasVisual and 26 or 9,0)
valueLabel.Size=UDim2.new(1,hasVisual and-45 or-28,1,0)
end
local popup
local dragging
local function closeList()
if popup then popup:Destroy()popup=nil end
dragging=nil
tintArrow("muted")
end
local function itemHeight(option)return info[option]and info[option].Desc and ITEM_DESC or ITEM end
local function openList()
closeList()
local position,size=Util.screenPos(button),button.AbsoluteSize
local viewport=Util.viewport()
local searchable=cfg.Search==true or(cfg.Search~=false and#options>8)
local fullHeight=8
for index,option in ipairs(options)do
fullHeight=fullHeight+itemHeight(option)
if index>200 then fullHeight=MAX_HEIGHT break end
end
local listHeight=math.min(fullHeight,MAX_HEIGHT)
local top=25+(searchable and SEARCH+4 or 0)
local total=top+listHeight
local scale=window.scale and window.scale.Scale or 1
local hasDesc=false
for index,option in ipairs(options)do
if info[option]and info[option].Desc then hasDesc=true break end
if index>200 then break end
end
local width=math.max(size.X/scale,cfg.ListWidth or(hasDesc and 190 or 140))
local roomBelow,roomAbove=viewport.Y-8-position.Y,position.Y+size.Y-8
local below=roomBelow>=total*scale or roomBelow>=roomAbove
popup=create("Frame",{
Name="DropdownList",BorderSizePixel=0,ZIndex=260,
Position=UDim2.fromOffset(math.clamp(position.X+size.X-width*scale,8,math.max(8,viewport.X-width*scale-8)),below and position.Y or position.Y+size.Y-total*scale),
Size=UDim2.fromOffset(width,total),Parent=window.gui,
})
create("UIScale",{Scale=scale,Parent=popup})
Theme.bind(popup,"BackgroundColor3","input")
corner(popup,6)
Theme.bind(stroke(popup),"Color","buttonEdge")
local header=create("TextButton",{
Name="Header",Text="",AutoButtonColor=false,BackgroundTransparency=1,ZIndex=261,
Position=UDim2.fromOffset(0,below and 0 or total-24),Size=UDim2.new(1,0,0,24),Parent=popup,
})
local headerText=label(header,valueLabel.Text,10,{Position=UDim2.fromOffset(9,0),Size=UDim2.new(1,-28,1,0),ZIndex=262})
Theme.bind(headerText,"TextColor3","text")
for index,rotation in ipairs({-40,40})do
local bar=create("Frame",{
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(1,index==1 and-16 or-12,0.5,0),Size=UDim2.fromOffset(6,1.5),
Rotation=rotation,BorderSizePixel=0,ZIndex=262,Parent=header,
})
Theme.bind(bar,"BackgroundColor3","accent")
end
header.Activated:Connect(function()window:_closePopup()end)
local separator=create("Frame",{
Position=UDim2.new(0,6,0,below and 24 or total-25),Size=UDim2.new(1,-12,0,1),BorderSizePixel=0,ZIndex=261,Parent=popup,
})
Theme.bind(separator,"BackgroundColor3","line")
local bodyTop=below and 25 or 0
local searchBox
if searchable then
searchBox=create("TextBox",{
Name="Search",Text="",PlaceholderText="Search...",TextSize=10,Font=Enum.Font.Gotham,ClearTextOnFocus=false,
TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,ZIndex=262,
Position=UDim2.fromOffset(6,bodyTop+4),Size=UDim2.new(1,-12,0,SEARCH-2),Parent=popup,
})
Theme.bind(searchBox,"BackgroundColor3","base")
Theme.bind(searchBox,"TextColor3","text")
Theme.bind(searchBox,"PlaceholderColor3","muted")
corner(searchBox,5)
Util.padding(searchBox,24,6,0,0)
Icons.themed(searchBox,"search",11,"muted",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,-17,0.5,0),ZIndex=263})
bodyTop=bodyTop+SEARCH+4
end
local scroller=create("ScrollingFrame",{
Name="Options",BackgroundTransparency=1,BorderSizePixel=0,ZIndex=261,ScrollBarThickness=2,
Position=UDim2.fromOffset(0,bodyTop),Size=UDim2.new(1,0,0,listHeight),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=popup,
})
Theme.bind(scroller,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(scroller)
Util.padding(scroller,4,4,4,4)
Util.fitCanvas(scroller,Util.list(scroller,0))
local empty=label(scroller,"No matches",10,{Name="Empty",Size=UDim2.new(1,0,0,ITEM),TextXAlignment=Enum.TextXAlignment.Center,Visible=false,ZIndex=262,LayoutOrder=1e6})
Theme.bind(empty,"TextColor3","muted")
local more=label(scroller,"",9,{Name="More",Size=UDim2.new(1,0,0,ITEM),TextXAlignment=Enum.TextXAlignment.Center,Visible=false,ZIndex=262,LayoutOrder=1e6+1})
Theme.bind(more,"TextColor3","muted")
local function refreshHeader()headerText.Text=valueLabel.Text end
local items={}
local function paint(option,entry,text,icon,check)
local on=chosen(option)
Theme.tweenTo(text,"TextColor3",on and"accent"or"text",0.1)
if icon and not entry.Image then Theme.tweenTo(icon,"ImageColor3",on and"accent"or"muted",0.1)end
check.Visible=on
end
local function setChosen(option,on)
local list=table.clone(element.Value)
local at=table.find(list,option)
if on and not at then list[#list+1]=option elseif not on and at then table.remove(list,at)end
element:Set(list)
refreshHeader()
end
local function buildItem(option,order)
local entry=info[option]or{Title=option}
local height=itemHeight(option)
local locked=entry.Locked==true
local item=create("TextButton",{
Name=option,Text="",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,
Size=UDim2.new(1,0,0,height),LayoutOrder=order,ZIndex=262,Parent=scroller,
})
Theme.bind(item,"BackgroundColor3","hover")
corner(item,5)
local textX=8
local icon=create("ImageLabel",{
Name="Icon",BackgroundTransparency=1,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0,entry.Desc and 12 or height/2),
Size=UDim2.fromOffset(entry.Image and 16 or 12,entry.Image and 16 or 12),ZIndex=263,Parent=item,
})
if entry.Image then corner(icon,4)end
if applyVisual(icon,entry,chosen(option)and"accent"or"muted")then textX=entry.Image and 30 or 26 else icon:Destroy()icon=nil end
local text=label(item,entry.Title,10,{Position=UDim2.fromOffset(textX,entry.Desc and 3 or 0),Size=UDim2.new(1,-textX-20,0,entry.Desc and 17 or height),ZIndex=263})
Theme.bind(text,"TextColor3",chosen(option)and"accent"or"text")
if entry.Desc then
local sub=label(item,tostring(entry.Desc),9,{Position=UDim2.fromOffset(textX,18),Size=UDim2.new(1,-textX-20,0,13),ZIndex=263})
Theme.bind(sub,"TextColor3","muted")
end
if locked then
text.TextTransparency=0.55
if icon then icon.ImageTransparency=0.55 end
Icons.themed(item,"lock",10,"muted",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),ZIndex=263,ImageTransparency=0.3})
end
local check=create("Frame",{Name="Check",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,ZIndex=263,Visible=chosen(option),Parent=item})
corner(check,3)
Theme.bind(check,"BackgroundColor3","accent")
items[option]=item
item.MouseEnter:Connect(function()
if not locked then item.BackgroundTransparency=0 end
if dragging~=nil and not locked and chosen(option)~=dragging then
setChosen(option,dragging)
paint(option,entry,text,icon,check)
end
end)
item.MouseLeave:Connect(function()item.BackgroundTransparency=1 end)
if multi then
item.InputBegan:Connect(function(input)
if locked or not Util.isPress(input)then return end
local target=not chosen(option)
setChosen(option,target)
paint(option,entry,text,icon,check)
if cfg.DragSelect~=false and input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=target end
end)
else
item.Activated:Connect(function()
if locked then return end
if element.Value==option and cfg.AllowNone then element:Set(nil)else element:Set(option)end
window:_closePopup()
end)
end
return item
end
local shown,drawn={},0
local function drawMore()
local limit=math.min(#shown,drawn+CHUNK)
for index=drawn+1,limit do
local option=shown[index]
local item=items[option]or buildItem(option,index)
item.LayoutOrder=index
item.Visible=true
end
drawn=limit
more.Visible=drawn<#shown
more.Text=(#shown-drawn).." more - scroll or search"
end
local function filter(query)
query=(query or""):lower()
for _,item in pairs(items)do item.Visible=false end
shown,drawn={},0
for _,option in ipairs(options)do
local entry=info[option]or{}
if query==""or entry.Title:lower():find(query,1,true)or option:lower():find(query,1,true)
or(entry.Desc~=nil and tostring(entry.Desc):lower():find(query,1,true))then
shown[#shown+1]=option
end
end
empty.Visible=#shown==0
drawMore()
end
scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
if drawn<#shown and scroller.CanvasPosition.Y+scroller.AbsoluteSize.Y>=scroller.AbsoluteCanvasSize.Y-60 then drawMore()end
end)
filter("")
if searchBox then
searchBox:GetPropertyChangedSignal("Text"):Connect(function()filter(searchBox.Text)end)
task.defer(function()pcall(function()searchBox:CaptureFocus()end)end)
end
tintArrow("accent")
window:_openPopup(popup,button,closeList)
end
button.Activated:Connect(function()
if element.Locked then return end
if popup then window:_closePopup()else openList()end
end)
window.maid:connect(Util.Services.UserInputService.InputEnded,function(input)
if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=nil end
end)
local function resolve(value)
value=tostring(value)
if info[value]then return value end
for _,key in ipairs(options)do if info[key].Title==value then return key end end
return nil
end
function element:Set(value,silent)
if multi then
local list={}
for _,option in ipairs(type(value)=="table"and value or{value})do
local key=resolve(option)
if key and not table.find(list,key)then list[#list+1]=key end
end
self.Value=list
else
self.Value=value~=nil and resolve(value)or nil
end
render()
self:_fire(self.Value,silent)
end
function element:Get()return self.Value end
function element:GetLabel(key)return titleOf(key or self.Value)end
function element:SetOptions(list,keep)
setOptions(list)
self.Options=options
if popup then window:_closePopup()end
self:Set(keep and self.Value or(multi and{}or nil),true)
end
function element:Refresh(list)self:SetOptions(list,true)end
if multi then
element.Value={}
element:Set(cfg.Default or{},true)
else
element:Set(cfg.Default,true)
end
return Base.finish(element,cfg)
end
end
__modules["elements/gradient"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local window=card.window
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 30,{right=100,button=true})
local preview=create("TextButton",{
Name="Preview",Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),
AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(88,18),Parent=row,
})
corner(preview,5)
Theme.bind(stroke(preview,nil,0.2),"Color","buttonEdge")
local gradient=create("UIGradient",{Rotation=tonumber(cfg.Rotation)or 0,Parent=preview})
local section=create("Frame",{
Name="GradientEditor",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
LayoutOrder=row.LayoutOrder+1,Visible=false,Parent=card.body,
})
Util.list(section,4)
local sub=setmetatable({page=card.page,window=window,order=0,body=section,frame=card.frame},getmetatable(card))
local element=Base.element(card,"Gradient",cfg,row,title,desc)
local a,b=Color3.new(1,1,1),Color3.new(0,0,0)
local pickers={}
local applying=false
local function render()
gradient.Color=ColorSequence.new(a,b)
end
local function commit(silent)
render()
element.Value={a,b}
element:_fire(element.Value,true)
if silent then return end
element:_call(cfg.Callback,ColorSequence.new(a,b),a,b)
for _,callback in ipairs(element._changed)do element:_call(callback,ColorSequence.new(a,b),a,b)end
end
pickers[1]=sub:ColorPicker({Title="Start",Flag=false,Default=a,Callback=function(color)if not applying then a=color commit()end end})
pickers[2]=sub:ColorPicker({Title="End",Flag=false,Default=b,Callback=function(color)if not applying then b=color commit()end end})
sub:Button({Title="Swap colours",Callback=function()element:Set({b,a})end})
function element:Set(value,silent)
if type(value)~="table"then return end
local first,second=value[1],value[2]
if type(first)=="string"then first=Util.fromHex(first)end
if type(second)=="string"then second=Util.fromHex(second)end
if typeof(first)~="Color3"or typeof(second)~="Color3"then return end
local changed=first~=a or second~=b
a,b=first,second
applying=true
pickers[1]:Set(a,true)
pickers[2]:Set(b,true)
applying=false
commit(silent or not changed)
end
function element:Get()return a,b end
function element:GetSequence()return ColorSequence.new(a,b)end
function element:_save()return{Util.toHex(a),Util.toHex(b)}end
function element:SetOpen(open)section.Visible=open==true end
local function toggleOpen()if not element.Locked then section.Visible=not section.Visible end end
row.Activated:Connect(toggleOpen)
preview.Activated:Connect(toggleOpen)
local default=type(cfg.Default)=="table"and cfg.Default or{Color3.fromRGB(215,120,120),Color3.fromRGB(120,140,230)}
element:Set(default,true)
return Base.finish(element,cfg)
end
end
__modules["elements/graph"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Stats=require("stats")
local create,corner,label=Util.create,Util.corner,Util.label
local PALETTE={"accent","warning","success","danger","codeGlobal","codeKeyword"}
return function(card,cfg)
local window=card.window
local points=math.clamp(tonumber(cfg.Points)or 40,5,120)
local height=tonumber(cfg.Height)or 70
local function suffixFor(source,given)
return given or(source=="Ping"and" ms"or(source=="FPS"and" FPS"or""))
end
local series={}
if type(cfg.Series)=="table"and#cfg.Series>0 then
for index,spec in ipairs(cfg.Series)do
series[index]={
name=tostring(spec.Name or spec.Source or("Series "..index)),source=spec.Source,
color=spec.Color or PALETTE[(index-1)%#PALETTE+1],suffix=suffixFor(spec.Source,spec.Suffix),samples={},
}
end
else
series[1]={name=tostring(cfg.Title or cfg.Source or"Graph"),source=cfg.Source,color=cfg.Color or"accent",suffix=suffixFor(cfg.Source,cfg.Suffix),samples={}}
end
local line=cfg.Style=="Line"or#series>1
local holder=create("Frame",{Name=tostring(cfg.Title or"Graph"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,height+24),LayoutOrder=card:_order(),Parent=card.body})
local title=label(holder,tostring(cfg.Title or cfg.Source or"Graph"),11,{Name="Title",Size=UDim2.new(1,-90,0,20)})
Theme.bind(title,"TextColor3","text")
local value,legend
if#series==1 then
value=label(holder,"--",10,{Name="Value",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(90,20),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium})
Theme.bind(value,"TextColor3","heading")
else
title.Size=UDim2.new(0.35,0,0,20)
legend=create("Frame",{Name="Legend",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.new(0.65,0,0,20),Parent=holder})
Util.list(legend,10,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)
for index,entry in ipairs(series)do
local item=create("Frame",{Name=entry.name,BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),LayoutOrder=index,Parent=legend})
Util.list(item,4,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
local dot=create("Frame",{Name="Dot",Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Parent=item})
corner(dot,3)
Theme.bind(dot,"BackgroundColor3",entry.color)
entry.legend=label(item,entry.name.." --",9,{Name="Text",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),TextTruncate=Enum.TextTruncate.None,LayoutOrder=2})
Theme.bind(entry.legend,"TextColor3","muted")
end
end
local area=create("Frame",{Name="Area",Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,BackgroundTransparency=0.4,ClipsDescendants=true,Parent=holder})
Theme.bind(area,"BackgroundColor3","base")
corner(area,6)
local bars={}
if line then
for _,y in ipairs({0.25,0.5,0.75})do
local guide=create("Frame",{Name="Guide",Position=UDim2.fromScale(0,y),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundTransparency=0.6,Parent=area})
Theme.bind(guide,"BackgroundColor3","line")
end
for _,entry in ipairs(series)do
entry.segments={}
for index=1,points-1 do
local segment=create("Frame",{Name="Segment",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(0,2),BorderSizePixel=0,Visible=false,ZIndex=2,Parent=area})
corner(segment,1)
Theme.bind(segment,"BackgroundColor3",entry.color)
entry.segments[index]=segment
end
entry.head=create("Frame",{Name="Head",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(5,5),BorderSizePixel=0,Visible=false,ZIndex=3,Parent=area})
corner(entry.head,3)
Theme.bind(entry.head,"BackgroundColor3",entry.color)
end
else
for index=1,points do
local bar=create("Frame",{
AnchorPoint=Vector2.new(0,1),Position=UDim2.new((index-1)/points,1,1,0),Size=UDim2.new(1/points,-2,0,0),
BorderSizePixel=0,BackgroundTransparency=0.3,Parent=area,
})
Theme.bind(bar,"BackgroundColor3",series[1].color)
bars[index]=bar
end
end
local element=Base.element(card,"Graph",{},holder,title,nil)
local function top()
local highest=tonumber(cfg.Max)or 1
for _,entry in ipairs(series)do for _,sample in ipairs(entry.samples)do highest=math.max(highest,sample)end end
if line and not tonumber(cfg.Max)then highest=highest*1.25 end
return highest
end
local function text(entry)
local last=entry.samples[#entry.samples]
return last and(tostring(math.floor(last+0.5))..entry.suffix)or"--"
end
local function render()
local highest=top()
if line then
local size=area.AbsoluteSize
local width,tall=size.X,size.Y
for _,entry in ipairs(series)do
local samples=entry.samples
local count=#samples
local function point(i)
local sample=samples[i]
local x=width*((points-(count-i)-1)/(points-1))
local y=tall-3-math.clamp(sample/highest,0,1)*(tall-6)
return x,y
end
for index,segment in ipairs(entry.segments)do
local i=count-(points-1)+index
if i>=2 and width>0 then
local x1,y1=point(i-1)
local x2,y2=point(i)
local dx,dy=x2-x1,y2-y1
segment.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2)
segment.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)+1,2)
segment.Rotation=math.deg(math.atan2(dy,dx))
segment.Visible=true
else
segment.Visible=false
end
end
if count>0 and width>0 then
local x,y=point(count)
entry.head.Position=UDim2.fromOffset(x-2,y)
entry.head.Visible=true
end
if entry.legend then entry.legend.Text=entry.name.." "..text(entry)end
end
else
local samples=series[1].samples
for index=1,points do
local sample=samples[#samples-points+index]
bars[index].Size=UDim2.new(1/points,-2,sample and math.clamp(sample/highest,0.02,1)or 0,0)
end
end
if value then value.Text=text(series[1])end
end
local function find(name)
if name==nil then return series[1]end
for _,entry in ipairs(series)do if entry.name==name then return entry end end
end
function element:Push(sample,name)
sample=tonumber(sample)
local entry=find(name)
if not sample or not entry then return end
entry.samples[#entry.samples+1]=sample
if#entry.samples>points then table.remove(entry.samples,1)end
render()
end
function element:Set(list,name)
local entry=find(name)
if not entry then return end
entry.samples={}
for _,sample in ipairs(list or{})do
sample=tonumber(sample)
if sample then
entry.samples[#entry.samples+1]=sample
if#entry.samples>points then table.remove(entry.samples,1)end
end
end
render()
end
function element:Get(name)local entry=find(name)return entry and entry.samples end
area:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
local function onScreen()
local object=holder
while object and object~=window.gui do
if object:IsA("GuiObject")and not object.Visible then return false end
object=object.Parent
end
return window.visible
end
local polled={}
for _,entry in ipairs(series)do
if entry.source=="FPS"or entry.source=="Ping"then
Stats.start(window.Lib.maid)
local key=entry.source=="FPS"and"fps"or"ping"
window.maid:give(Stats.listen(function(stats)if holder.Parent then element:Push(stats[key],entry.name)end end))
elseif type(entry.source)=="function"then
polled[#polled+1]=entry
end
end
if#polled>0 then
task.spawn(function()
while window.alive and holder.Parent do
if onScreen()then
for _,entry in ipairs(polled)do
local ok,sample=pcall(entry.source)
if ok then element:Push(sample,entry.name)end
end
end
task.wait(tonumber(cfg.Interval)or 0.5)
end
end)
end
render()
return element
end
end
__modules["elements/image"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,label=Util.create,Util.corner,Util.label
return function(card,cfg)
local height=tonumber(cfg.Height)or 120
local holder=create("Frame",{Name=tostring(cfg.Name or"Image"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,height+(cfg.Caption and 18 or 0)),LayoutOrder=card:_order(),Parent=card.body})
local frame=create("ImageLabel",{
Name="Picture",Size=UDim2.new(1,0,0,height),BorderSizePixel=0,ScaleType=cfg.Fit=="Fit"and Enum.ScaleType.Fit or Enum.ScaleType.Crop,
Parent=holder,
})
Theme.bind(frame,"BackgroundColor3","input")
corner(frame,tonumber(cfg.Radius)or 8)
if typeof(cfg.AspectRatio)=="number"then
create("UIAspectRatioConstraint",{AspectRatio=cfg.AspectRatio,Parent=frame})
end
local caption
if cfg.Caption then
caption=label(holder,tostring(cfg.Caption),9,{Name="Caption",Position=UDim2.fromOffset(0,height+4),Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Center})
Theme.bind(caption,"TextColor3","muted")
end
local element=Base.element(card,"Image",{},holder,caption,nil)
function element:Set(image)
self.Value=image
frame.Image=""
if image==nil then return end
local icon=Icons.Get(image)
if icon then Icons.Apply(frame,image)else frame.Image=tostring(image)end
local isPicture=tostring(image):match("^rbxasset")or tostring(image):match("^%d+$")or tostring(image):match("^https?://")
if isPicture then frame.ImageColor3=Color3.new(1,1,1)else Theme.bind(frame,"ImageColor3","heading")end
end
element:Set(cfg.Image)
return element
end
end
__modules["elements/imagepicker"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(card,cfg)
local images=cfg.Images or{}
local columns=math.max(1,tonumber(cfg.Columns)or 5)
local cell=tonumber(cfg.CellSize)or 40
local rowsCount=math.ceil(#images/columns)
local top=cfg.Title and 24 or 0
local holder=create("Frame",{Name=tostring(cfg.Title or"Images"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,top+rowsCount*(cell+6)),LayoutOrder=card:_order(),Parent=card.body})
local title
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,0,0,20)})
Theme.bind(title,"TextColor3","text")
end
local grid=create("Frame",{Name="Grid",BackgroundTransparency=1,Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,1,-top),Parent=holder})
local element=Base.element(card,"ImagePicker",cfg,holder,title,nil)
local buttons={}
local function asset(image)
image=tostring(image)
return image:match("^%d+$")and("rbxassetid://"..image)or image
end
local function render()
for image,entry in pairs(buttons)do
local on=image==element.Value
Theme.tweenTo(entry.button,"BackgroundColor3",on and"selected"or"input",0.1)
Theme.tweenTo(entry.outline,"Color",on and"accent"or"line",0.1)
entry.outline.Transparency=on and 0.2 or 0.6
end
end
for index,image in ipairs(images)do
local key=tostring(image)
local button=create("ImageButton",{
Name="Image"..index,AutoButtonColor=false,BorderSizePixel=0,Image="",LayoutOrder=index,Parent=grid,
Position=UDim2.new(((index-1)%columns)/columns,3,0,((index-1)//columns)*(cell+6)),Size=UDim2.new(1/columns,-6,0,cell),
})
corner(button,6)
local outline=stroke(button)
local preview=create("ImageLabel",{
Name="Preview",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.62,0.62),
BackgroundTransparency=1,Image=asset(image),ScaleType=Enum.ScaleType.Fit,Parent=button,
})
if not tostring(image):match("^%d+$")and not tostring(image):match("^rbxasset")then Icons.Apply(preview,image)end
buttons[key]={button=button,outline=outline}
Util.hoverPop(button,1.05)
button.MouseEnter:Connect(function()
if key~=element.Value then Theme.tweenTo(outline,"Color","buttonEdge",0.1)outline.Transparency=0.1 end
end)
button.MouseLeave:Connect(render)
button.Activated:Connect(function()if not element.Locked then element:Set(key)end end)
end
function element:Set(image,silent)
image=image~=nil and tostring(image)or nil
if image and not buttons[image]then return end
local changed=image~=self.Value
self.Value=image
render()
self:_fire(image,silent or not changed)
end
function element:Get()return self.Value end
element:Set(cfg.Default~=nil and cfg.Default or images[1],true)
return Base.finish(element,cfg)
end
end
__modules["elements/info"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(card,cfg)
local row=create("Frame",{Name=tostring(cfg.Title or"Info"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,22),LayoutOrder=card:_order(),Parent=card.body})
local title=label(row,tostring(cfg.Title or""),10,{Name="Title",Size=UDim2.new(0.42,-6,1,0)})
Theme.bind(title,"TextColor3","muted")
local copyWidth=cfg.Copy and 40 or 0
local value=label(row,"",10,{
Name="Value",Position=UDim2.new(0.42,copyWidth,0,0),Size=UDim2.new(0.58,-copyWidth,1,0),
TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,
})
Theme.bind(value,"TextColor3","text")
local element=Base.element(card,"Info",{},row,title,nil)
function element:Set(text)self.Value=text value.Text=tostring(text)end
function element:Get()return self.Value end
function element:SetColor(color)Theme.bind(value,"TextColor3",color or"text")end
if cfg.Copy then
local copy=create("TextButton",{
Name="Copy",Text="Copy",TextSize=8,Font=Enum.Font.Gotham,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0.42,0,0.5,0),Size=UDim2.fromOffset(34,16),Parent=row,
})
Theme.bind(copy,"BackgroundColor3","input")
Theme.bind(copy,"TextColor3","text")
corner(copy,5)
Theme.bind(stroke(copy),"Color","buttonEdge")
copy.Activated:Connect(function()
local text=cfg.Copy
if type(text)=="function"then local ok,result=pcall(text)text=ok and result or nil end
if text==true or text==nil then text=tostring(element.Value):gsub("^#","")end
local clipboard=setclipboard or toclipboard
local ok=type(clipboard)=="function"and pcall(clipboard,tostring(text))
copy.Text=ok and"OK"or"!"
task.delay(1.2,function()if copy.Parent then copy.Text="Copy"end end)
if ok then card.window:Notify({Title="Copied",Content=tostring(cfg.Title or"Value").." copied to clipboard"})end
end)
end
element:Set(cfg.Value~=nil and cfg.Value or"--")
return element
end
end
__modules["elements/input"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local baseHeight=cfg.Desc and 40 or 30
local row,title,desc=Base.row(card,cfg,baseHeight,{right=160})
title.Size=UDim2.new(0.55,-8,0,title.Size.Y.Offset)
if desc then desc.Size=UDim2.new(0.55,-8,0,14)end
local box=create("TextBox",{
Name="Box",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0,baseHeight/2),Size=UDim2.new(0.45,0,0,24),
BorderSizePixel=0,Text="",PlaceholderText=tostring(cfg.Placeholder or""),TextSize=10,Font=Enum.Font.Gotham,
TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=cfg.ClearOnFocus==true,ClipsDescendants=true,
TextTruncate=Enum.TextTruncate.AtEnd,Parent=row,
})
Theme.bind(box,"BackgroundColor3","input")
Theme.bind(box,"TextColor3","text")
Theme.bind(box,"PlaceholderColor3","muted")
corner(box,6)
local outline=stroke(box)
Theme.bind(outline,"Color","buttonEdge")
local PAD=9
Util.padding(box,PAD,PAD,0,0)
local measure=create("TextLabel",{Name="Measure",BackgroundTransparency=1,TextTransparency=1,Size=UDim2.fromOffset(0,0),TextSize=10,Font=box.Font,Text="",Parent=row})
local function textWidth(text)
local ok,width=pcall(function()
measure.FontFace=box.FontFace
measure.Text=text
return measure.TextBounds.X
end)
if ok and type(width)=="number"and width>0 then return width end
return Util.textWidth(text,10,box.Font)
end
local function fit()
local text=box.Text~=""and box.Text or box.PlaceholderText
local most=170
local rowWidth=row.AbsoluteSize.X
if rowWidth>0 then most=math.min(most,math.floor(rowWidth*0.45))end
local width=math.clamp(math.ceil(textWidth(text))+PAD*2+4,56,math.max(56,most))
box.Size=UDim2.fromOffset(width,24)
end
box:GetPropertyChangedSignal("Text"):Connect(fit)
box:GetPropertyChangedSignal("FontFace"):Connect(fit)
row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local element=Base.element(card,"Input",cfg,row,title,desc)
local function clean(text)
text=tostring(text or"")
if cfg.Numeric then text=text:gsub("[^%d%.%-]","")end
return text
end
function element:Set(text,silent)
text=clean(text)
local changed=text~=self.Value
self.Value=text
if box.Text~=text then box.Text=text end
self._failed=false
self:_fire(text,silent or not changed)
if changed and not silent then self:_accepted("success")end
end
function element:Get()return self.Value end
function element:SetPlaceholder(text)box.PlaceholderText=tostring(text or"")fit()end
local focused=false
local hint
local state
local function edgeRole()
if state==false then return"danger"end
if not focused then return"buttonEdge"end
return state==true and"success"or"accent"
end
local function validate(text)
if type(cfg.Validate)~="function"then return nil end
local ok,result,message=pcall(cfg.Validate,clean(text))
if not ok then result,message=nil,nil end
if clean(text)==""and result==nil then message=nil end
state=result
element.Valid=result
Theme.tweenTo(outline,"Color",edgeRole(),0.1)
local show=message~=nil and tostring(message)~=""
if show and not hint then
hint=Util.label(row,"",9,{Name="Hint",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,baseHeight-1),Size=UDim2.new(1,-4,0,13),TextXAlignment=Enum.TextXAlignment.Right})
end
if hint then
hint.Visible=show
hint.Text=show and tostring(message)or""
Theme.bind(hint,"TextColor3",result==true and"success"or(result==false and"danger"or"muted"))
end
row.Size=UDim2.new(1,0,0,baseHeight+(show and 13 or 0))
return result
end
element.Validate=function(_,text)return validate(text==nil and box.Text or text)end
box.Focused:Connect(function()focused=true Theme.tweenTo(outline,"Color",edgeRole(),0.1)end)
box.FocusLost:Connect(function()
focused=false
if validate(box.Text)==false then
Theme.tweenTo(outline,"Color",edgeRole(),0.1)
return
end
Theme.tweenTo(outline,"Color",edgeRole(),0.1)
if hint and state~=false then hint.Visible=false row.Size=UDim2.new(1,0,0,baseHeight)end
element:Set(box.Text)
end)
if cfg.Validate then
box:GetPropertyChangedSignal("Text"):Connect(function()if focused then validate(box.Text)end end)
end
if cfg.Finished==false then
box:GetPropertyChangedSignal("Text"):Connect(function()
if validate(box.Text)~=false then element:Set(box.Text)end
end)
end
element:Set(cfg.Default or"",true)
if cfg.Validate and element.Value~=""then validate(element.Value)end
if cfg.Locked then box.TextEditable=false end
return Base.finish(element,cfg)
end
end
__modules["elements/keybind"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local window=card.window
local chordMode=cfg.Chord==true
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 30,{right=chordMode and 130 or 100})
local badge=create("TextButton",{
Name="Key",AutoButtonColor=false,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(48,22),Text="",TextSize=10,
Font=Enum.Font.GothamMedium,Parent=row,
})
Theme.bind(badge,"BackgroundColor3","input")
Theme.bind(badge,"TextColor3","heading")
corner(badge,6)
local outline=stroke(badge)
Theme.bind(outline,"Color","buttonEdge")
local element=Base.element(card,"Keybind",cfg,row,title,desc)
element._keyLabel,element._keyStroke=badge,outline
local function show(text)
badge.Text=text
local width=math.max(48,Util.textWidth(text,10,Enum.Font.GothamMedium)+18)
badge.Size=UDim2.fromOffset(width,22)
local reserve=math.max(width,60)+12
if cfg.Help then reserve=(chordMode and 130 or 100)+16 end
title.Size=UDim2.new(1,-reserve,0,title.Size.Y.Offset)
if desc then desc.Size=UDim2.new(1,-reserve,0,desc.Size.Y.Offset)end
end
local function chordName(chord)
if not chord or not chord[2]then return"None"end
return(chord[1]and(Util.keyName(chord[1]).." + ")or"")..Util.keyName(chord[2])
end
function element:Set(key,silent)
if chordMode then
if type(key)=="string"then
local first,second=key:match("^([^+]+)%+(.+)$")
key=first and{Util.toKey(first),Util.toKey(second)}or{nil,Util.toKey(key)}
elseif typeof(key)=="EnumItem"then
key={nil,key}
elseif type(key)=="table"then
key={Util.toKey(key[1]),Util.toKey(key[2])}
if not key[2]and key[1]then key={nil,key[1]}end
else
key=nil
end
if key and not key[2]then key=nil end
local changed=chordName(key)~=chordName(self.Value)
self.Value,self.Chord=key,key
window:_bind(self,key and key[2]or nil)
show(chordName(key))
Theme.tweenTo(outline,"Color","buttonEdge",0.1)
self._failed=false
self:_fire(key,silent or not changed)
if changed and not silent then self:_accepted("accent")end
return
end
key=Util.toKey(key)
local changed=key~=self.Value
self.Value=key
window:_bind(self,key)
show(Util.keyName(key))
Theme.tweenTo(outline,"Color","buttonEdge",0.1)
self._failed=false
if changed then self:_fire(key,silent)else self:_fire(key,true)end
if changed and not silent then self:_accepted("accent")end
end
function element:Get()return self.Value end
element.Mode=cfg.Mode=="Hold"and"Hold"or"Press"
element.Held=false
function element:_onBind()
if self.Locked then return end
if self.Mode=="Hold"then
if self.Held then return end
self.Held=true
self:_call(cfg.Pressed,true)
else
self:_call(cfg.Pressed,self.Value)
end
end
function element:_onRelease()
if self.Mode=="Hold"and self.Held then
self.Held=false
self:_call(cfg.Pressed,false)
end
end
function element:_save()
if chordMode then
local chord=self.Value
if not chord then return"None"end
return(chord[1]and(chord[1].Name.."+")or"")..chord[2].Name
end
return self.Value and self.Value.Name or"None"
end
badge.Activated:Connect(function()
if element.Locked then return end
show("...")
Theme.tweenTo(outline,"Color","accent",0.1)
local modifier
local function capture(key)
window._captureMouse=nil
if key==Enum.KeyCode.Escape then element:Set(element.Value,true)return end
if key==Enum.KeyCode.Backspace then element:Set(nil)return end
if chordMode then
if not modifier and Util.isModifier(key)then
modifier=key
show(Util.keyName(key).." + ...")
window._captureMouse=true
window._capture=capture
return
end
element:Set({modifier,key})
return
end
if key==window.key then element:Set(element.Value,true)return end
element:Set(key)
end
window._capture=capture
end)
element:Set(cfg.Default,true)
return Base.finish(element,cfg)
end
end
__modules["elements/label"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
return function(card,cfg)
local text=Util.label(card.body,tostring(cfg.Title or cfg.Text or""),10,{
Name="Label",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,RichText=true,LayoutOrder=card:_order(),
})
if typeof(cfg.Color)=="Color3"then text.TextColor3=cfg.Color else Theme.bind(text,"TextColor3","muted")end
local element=Base.element(card,"Label",{},text,text,nil)
function element:Set(value)text.Text=tostring(value)end
function element:SetColor(color)Theme.bind(text,"TextColor3",color or"muted")end
return element
end
end
__modules["elements/paragraph"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create=Util.create
return function(card,cfg)
local holder=create("Frame",{
Name="Paragraph",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
LayoutOrder=card:_order(),Parent=card.body,
})
Util.list(holder,2)
local title=Util.label(holder,tostring(cfg.Title or""),11,{Name="Title",Size=UDim2.new(1,0,0,18),Font=Enum.Font.GothamMedium,LayoutOrder=1})
Theme.bind(title,"TextColor3","heading")
title.Visible=cfg.Title~=nil
local content=Util.label(holder,tostring(cfg.Content or""),10,{
Name="Content",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,TextYAlignment=Enum.TextYAlignment.Top,RichText=true,LayoutOrder=2,
})
Theme.bind(content,"TextColor3","muted")
local element=Base.element(card,"Paragraph",{},holder,title,content)
function element:Set(text)content.Text=tostring(text)end
function element:SetContent(text)content.Text=tostring(text)end
return element
end
end
__modules["elements/playerlist"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Services=Util.Services
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local ROW=30
return function(card,cfg)
local window=card.window
local Players=Services.Players
local multi=cfg.Multi~=false
local height=tonumber(cfg.Height)or 150
local holder=create("Frame",{Name=tostring(cfg.Title or"Players"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,height+(cfg.Title and 56 or 34)),LayoutOrder=card:_order(),Parent=card.body})
local top=0
local title
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,-90,0,20)})
Theme.bind(title,"TextColor3","text")
top=22
end
local count=label(holder,"",9,{Name="Count",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(90,20),TextXAlignment=Enum.TextXAlignment.Right})
Theme.bind(count,"TextColor3","muted")
local search=create("TextBox",{
Name="Search",Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,0,26),BorderSizePixel=0,Text="",
PlaceholderText="Search players...",TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
ClearTextOnFocus=false,Parent=holder,
})
Theme.bind(search,"BackgroundColor3","input")
Theme.bind(search,"TextColor3","text")
Theme.bind(search,"PlaceholderColor3","muted")
corner(search,6)
Theme.bind(stroke(search),"Color","buttonEdge")
Util.padding(search,9,9,0,0)
local list=create("ScrollingFrame",{
Name="List",Position=UDim2.fromOffset(0,top+32),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollingDirection=Enum.ScrollingDirection.Y,
Parent=holder,
})
Theme.bind(list,"BackgroundColor3","base")
Theme.bind(list,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(list)
list.BackgroundTransparency=0.4
corner(list,6)
Theme.bind(stroke(list),"Color","line")
local inner=create("Frame",{Name="Rows",BackgroundTransparency=1,Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=list})
Util.list(inner,2)
Util.padding(inner,0,0,0,6)
Util.fitCanvas(list,inner)
local empty=label(list,"No players",10,{Name="Empty",Size=UDim2.new(1,0,0,30),TextXAlignment=Enum.TextXAlignment.Center,Visible=false})
Theme.bind(empty,"TextColor3","muted")
local element=Base.element(card,"PlayerList",cfg,holder,title,nil)
local chosen={}
local rows={}
local function valueList()
local ids={}
for id in pairs(chosen)do ids[#ids+1]=id end
table.sort(ids)
return ids
end
local function renderRow(entry)
local on=chosen[entry.player.UserId]==true
entry.button.BackgroundTransparency=on and 0 or 1
Theme.bind(entry.name,"TextColor3",on and"accent"or"text")
entry.check.Visible=on
end
local function filter()
local query=search.Text:lower()
local shown=0
for _,entry in pairs(rows)do
local player=entry.player
local match=query==""or player.Name:lower():find(query,1,true)or player.DisplayName:lower():find(query,1,true)
entry.button.Visible=match~=nil and match~=false
if entry.button.Visible then shown=shown+1 end
end
empty.Visible=shown==0
local selected=0
for _ in pairs(chosen)do selected=selected+1 end
local total=0
for _ in pairs(rows)do total=total+1 end
count.Text=selected>0 and(selected.." selected")or(total..(total==1 and" player"or" players"))
end
local function commit()
element.Value=multi and valueList()or valueList()[1]
for _,entry in pairs(rows)do renderRow(entry)end
filter()
element:_fire(element.Value)
end
local function addRow(player)
if rows[player]or not holder.Parent or(player==Players.LocalPlayer and not cfg.IncludeSelf)then return end
local button=create("TextButton",{
Name=player.Name,Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundTransparency=1,
Size=UDim2.new(1,0,0,ROW),Parent=inner,
})
Theme.bind(button,"BackgroundColor3","selected")
corner(button,5)
local avatar=create("ImageLabel",{Position=UDim2.fromOffset(4,3),Size=UDim2.fromOffset(24,24),BorderSizePixel=0,Parent=button})
Theme.bind(avatar,"BackgroundColor3","input")
corner(avatar,12)
local name=label(button,player.DisplayName,10,{Position=UDim2.fromOffset(36,2),Size=UDim2.new(1,-60,0,14),Font=Enum.Font.GothamMedium})
local user=label(button,"@"..player.Name,9,{Position=UDim2.fromOffset(36,15),Size=UDim2.new(1,-60,0,12)})
Theme.bind(user,"TextColor3","muted")
local check=create("Frame",{Name="Check",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Visible=false,Parent=button})
Theme.bind(check,"BackgroundColor3","accent")
corner(check,3)
local entry={player=player,button=button,name=name,check=check}
rows[player]=entry
button.MouseEnter:Connect(function()if not chosen[player.UserId]then button.BackgroundTransparency=0.5 end end)
button.MouseLeave:Connect(function()renderRow(entry)end)
button.Activated:Connect(function()
if element.Locked then return end
local id=player.UserId
if multi then
chosen[id]=not chosen[id]or nil
else
local was=chosen[id]
chosen={}
if not was then chosen[id]=true end
end
commit()
end)
avatar.Image=Util.avatar(player.UserId)
renderRow(entry)
filter()
end
local function removeRow(player)
local entry=rows[player]
if entry then entry.button:Destroy()rows[player]=nil filter()end
end
for _,player in ipairs(Players:GetPlayers())do addRow(player)end
window.maid:connect(Players.PlayerAdded,addRow)
window.maid:connect(Players.PlayerRemoving,removeRow)
search:GetPropertyChangedSignal("Text"):Connect(filter)
function element:Set(ids,silent)
chosen={}
for _,id in ipairs(type(ids)=="table"and ids or{ids})do
id=tonumber(id)
if id then chosen[id]=true end
if not multi then break end
end
self.Value=multi and valueList()or valueList()[1]
for _,entry in pairs(rows)do renderRow(entry)end
filter()
self:_fire(self.Value,silent)
end
function element:Get()return self.Value end
function element:GetPlayers()
local out={}
for _,player in ipairs(Players:GetPlayers())do if chosen[player.UserId]then out[#out+1]=player end end
return out
end
function element:Clear()self:Set({})end
element:Set(cfg.Default or{},true)
return Base.finish(element,cfg)
end
end
__modules["elements/progress"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,label=Util.create,Util.corner,Util.label
return function(card,cfg)
local window=card.window
local top=cfg.Desc and 38 or 22
local row,title,desc=Base.row(card,cfg,top+12,{right=90,titleHeight=22})
local value=label(row,"",10,{Name="Value",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,1),Size=UDim2.fromOffset(86,20),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium})
Theme.bind(value,"TextColor3","text")
if desc then desc.Size=UDim2.new(1,desc.Size.X.Offset,0,14)end
local track=create("Frame",{Name="Track",Position=UDim2.new(0,0,0,top+4),Size=UDim2.new(1,0,0,6),BorderSizePixel=0,ClipsDescendants=true,Parent=row})
Theme.bind(track,"BackgroundColor3","input")
corner(track,3)
local fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=track})
Theme.bind(fill,"BackgroundColor3","accent")
corner(fill,3)
create("UIGradient",{Transparency=NumberSequence.new(0.25,0),Parent=fill})
local element=Base.element(card,"Progress",{},row,title,desc)
local max=math.max(tonumber(cfg.Max)or tonumber(cfg.Steps)or 100,1e-9)
local segments,segmentHolder={},nil
local suffix=cfg.Suffix
local indeterminate=false
local function text()
if indeterminate then return cfg.IndeterminateText or"Working..."end
if type(cfg.Format)=="function"then
local ok,result=pcall(cfg.Format,element.Value,max)
if ok then return tostring(result)end
end
if suffix==nil and max==100 then return math.floor(element.Value+0.5).."%"end
return math.floor(element.Value+0.5).." / "..math.floor(max+0.5)..(suffix and(" "..suffix)or"")
end
local function render(animate)
value.Text=text()
if segmentHolder then segmentHolder.Visible=not indeterminate end
track.BackgroundTransparency=(#segments>0 and not indeterminate)and 1 or 0
if indeterminate then fill.Visible=true return end
local ratio=math.clamp(element.Value/max,0,1)
fill.Visible=#segments==0
for index,segment in ipairs(segments)do
local part=math.clamp(ratio*#segments-(index-1),0,1)
if animate then Util.tween(segment,0.25,{Size=UDim2.fromScale(part,1)})else segment.Size=UDim2.fromScale(part,1)end
end
fill.Position=UDim2.fromScale(0,0)
if animate then Util.tween(fill,0.25,{Size=UDim2.fromScale(ratio,1)})else fill.Size=UDim2.fromScale(ratio,1)end
end
function element:Set(v)self.Value=math.max(0,tonumber(v)or 0)render(true)end
function element:SetMax(m)max=math.max(tonumber(m)or max,1e-9)render(true)end
function element:Get()return self.Value,max end
local spinner
function element:SetIndeterminate(on)
indeterminate=on==true
if spinner then spinner:Disconnect()spinner=nil end
if indeterminate then
fill.Size=UDim2.fromScale(0.3,1)
local started=os.clock()
spinner=window.maid:connect(Util.Services.RunService.Heartbeat,function()
if not row.Parent then return end
local t=((os.clock()-started)/1.2)%1
fill.Position=UDim2.fromScale(-0.3+t*1.3,0)
end)
end
render(false)
end
function element:SetSteps(count)
count=math.clamp(math.floor(tonumber(count)or 0),0,40)
if segmentHolder then segmentHolder:Destroy()segmentHolder=nil end
segments={}
if count>0 then
segmentHolder=create("Frame",{Name="Segments",BackgroundTransparency=1,Position=track.Position,Size=track.Size,Parent=row})
local gap=count>12 and 2 or 3
Util.list(segmentHolder,gap,Enum.FillDirection.Horizontal)
for index=1,count do
local cell=create("Frame",{Name="Segment"..index,Size=UDim2.new(1/count,-gap*(count-1)/count,1,0),BorderSizePixel=0,LayoutOrder=index,ClipsDescendants=true,Parent=segmentHolder})
Theme.bind(cell,"BackgroundColor3","input")
corner(cell,3)
local part=create("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=cell})
Theme.bind(part,"BackgroundColor3","accent")
corner(part,3)
segments[index]=part
end
end
render(false)
end
element.Value=math.max(0,tonumber(cfg.Value or cfg.Default)or 0)
if tonumber(cfg.Steps)then element:SetSteps(cfg.Steps)end
render(false)
if cfg.Indeterminate then element:SetIndeterminate(true)end
return element
end
end
__modules["elements/radio"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local function normalize(list)
local out={}
for _,option in ipairs(list or{})do
if type(option)=="table"then
local text=tostring(option.Title or option.Value or"")
out[#out+1]={value=option.Value~=nil and option.Value or text,title=text,desc=option.Desc,locked=option.Locked==true}
else
out[#out+1]={value=option,title=tostring(option)}
end
end
return out
end
return function(card,cfg)
local holder=create("Frame",{Name=tostring(cfg.Title or"Radio"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=card:_order(),Parent=card.body})
Util.list(holder,2)
local title
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,0,0,22),LayoutOrder=0})
Theme.bind(title,"TextColor3",cfg.Risky and"danger"or"text")
end
local list=create("Frame",{Name="Options",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=holder})
Util.list(list,2)
local element=Base.element(card,"Radio",cfg,holder,title,nil)
local options,rows={},{}
local function render(animate)
local duration=animate and 0.12 or nil
for _,entry in ipairs(rows)do
local on=entry.option.value==element.Value
Theme.tweenTo(entry.ring,"Color",on and"accent"or"buttonEdge",duration)
entry.dot.Visible=on
Theme.tweenTo(entry.text,"TextColor3",entry.option.locked and"muted"or(on and"heading"or"text"),duration)
end
end
local function build()
for _,entry in ipairs(rows)do entry.button:Destroy()end
rows={}
for index,option in ipairs(options)do
local height=option.desc and 36 or 26
local button=create("TextButton",{Name=tostring(option.title),Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height),LayoutOrder=index,Parent=list})
local circle=create("Frame",{Name="Circle",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,1,0,option.desc and 12 or height/2),Size=UDim2.fromOffset(14,14),BorderSizePixel=0,Parent=button})
corner(circle,7)
Theme.bind(circle,"BackgroundColor3","input")
local ring=stroke(circle)
local dot=create("Frame",{Name="Dot",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Visible=false,Parent=circle})
corner(dot,3)
Theme.bind(dot,"BackgroundColor3","accent")
local text=label(button,option.title,10,{Name="Text",Position=UDim2.fromOffset(24,option.desc and 3 or 0),Size=UDim2.new(1,-24,0,option.desc and 18 or height)})
if option.desc then
local sub=label(button,tostring(option.desc),9,{Name="Desc",Position=UDim2.fromOffset(24,20),Size=UDim2.new(1,-24,0,13)})
Theme.bind(sub,"TextColor3","muted")
end
button.Activated:Connect(function()
if element.Locked or option.locked then return end
element:Set(option.value)
end)
button.MouseEnter:Connect(function()if option.value~=element.Value and not option.locked then Theme.tweenTo(text,"TextColor3","heading",0.1)end end)
button.MouseLeave:Connect(function()render(true)end)
rows[index]={option=option,button=button,ring=ring,dot=dot,text=text}
end
render(false)
end
local function has(value)
for _,option in ipairs(options)do if option.value==value then return true end end
return false
end
function element:Set(value,silent)
if not has(value)then
for _,option in ipairs(options)do if option.title==value then value=option.value break end end
end
if not has(value)then return end
local changed=value~=self.Value
self.Value=value
render(true)
self:_fire(value,silent or not changed)
end
function element:Get()return self.Value end
function element:SetOptions(list)
options=normalize(list)
build()
if not has(self.Value)then self.Value=options[1]and options[1].value or nil self:_fire(self.Value,true)end
end
options=normalize(cfg.Options)
build()
element.Value=has(cfg.Default)and cfg.Default or(options[1]and options[1].value)
render(false)
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/range"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner=Util.create,Util.corner
return function(card,cfg)
local window=card.window
local min,max=tonumber(cfg.Min)or 0,tonumber(cfg.Max)or 100
if max<min then min,max=max,min end
local step=tonumber(cfg.Step)or 1
local gap=math.max(0,tonumber(cfg.MinGap)or 0)
local suffix=cfg.Suffix and(" "..tostring(cfg.Suffix))or""
local decimals=Util.decimals(step)
local top=cfg.Desc and 38 or 22
local row,title,desc=Base.row(card,cfg,top+18,{right=150,titleHeight=22,helpRight=146,helpY=11})
local boxes=create("Frame",{Name="Values",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,1),Size=UDim2.fromOffset(150,20),Parent=row})
local function box(name,x,align)
local object=create("TextBox",{
Name=name,Position=UDim2.fromOffset(x,0),Size=UDim2.fromOffset(52,20),BackgroundTransparency=1,BorderSizePixel=0,
Text="",TextSize=10,Font=Enum.Font.GothamMedium,ClearTextOnFocus=false,TextXAlignment=align,Parent=boxes,
})
Theme.bind(object,"BackgroundColor3","base")
Theme.bind(object,"TextColor3","text")
corner(object,6)
return object
end
local lowBox,highBox=box("Low",0,Enum.TextXAlignment.Right),box("High",64,Enum.TextXAlignment.Right)
local dash=Util.label(boxes,"–",10,{Name="Dash",Position=UDim2.fromOffset(52,0),Size=UDim2.fromOffset(14,20),TextXAlignment=Enum.TextXAlignment.Center})
Theme.bind(dash,"TextColor3","muted")
if desc then desc.Size=UDim2.new(1,0,0,14)end
local track=create("Frame",{Name="Track",Position=UDim2.new(0,0,0,top+8),Size=UDim2.new(1,0,0,2),BorderSizePixel=0,Parent=row})
Theme.bind(track,"BackgroundColor3","buttonEdge")
corner(track,1)
local fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=track})
Theme.bind(fill,"BackgroundColor3","accent")
local function knob(name)
local object=create("Frame",{Name=name,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(10,10),BorderSizePixel=0,ZIndex=2,Parent=track})
Theme.bind(object,"BackgroundColor3","accent")
corner(object,5)
return object
end
local lowKnob,highKnob=knob("LowKnob"),knob("HighKnob")
local reach=Util.isTouch()and 8 or 0
local hit=create("TextButton",{Name="Hit",Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.new(0,-6,0,top-reach),Size=UDim2.new(1,12,0,18+reach*2),ZIndex=3,Parent=row})
local element=Base.element(card,"Range",cfg,row,title,desc)
local focused={}
local function format(value)
return decimals>0 and string.format("%."..decimals.."f",value)or tostring(math.floor(value+0.5))
end
local function snap(value)
value=math.clamp(Util.round(value-min,step)+min,min,max)
if decimals>0 then value=tonumber(string.format("%."..decimals.."f",value))end
return value
end
local function ratio(value)return max>min and(value-min)/(max-min)or 0 end
local function render()
local low,high=element.Value[1],element.Value[2]
local a,b=ratio(low),ratio(high)
lowKnob.Position=UDim2.new(a,5-10*a,0.5,0)
highKnob.Position=UDim2.new(b,5-10*b,0.5,0)
fill.Position=UDim2.new(a,5-10*a,0,0)
fill.Size=UDim2.new(b-a,-10*(b-a),1,0)
if not focused.low then lowBox.Text=format(low)..suffix end
if not focused.high then highBox.Text=format(high)..suffix end
local function width(object)return math.max(18,Util.textWidth(object.Text,10,Enum.Font.GothamMedium)+(focused[object==lowBox and"low"or"high"]and 14 or 2))end
local highWidth,lowWidth=width(highBox),width(lowBox)
highBox.Position,highBox.Size=UDim2.new(1,-highWidth,0,0),UDim2.fromOffset(highWidth,20)
dash.Position=UDim2.new(1,-highWidth-14,0,0)
lowBox.Position,lowBox.Size=UDim2.new(1,-highWidth-14-lowWidth,0,0),UDim2.fromOffset(lowWidth,20)
if not cfg.Help then title.Size=UDim2.new(1,-(highWidth+14+lowWidth+10),0,title.Size.Y.Offset)end
end
function element:Set(value,silent)
if type(value)~="table"then return end
local low,high=tonumber(value[1])or min,tonumber(value[2])or max
if low>high then low,high=high,low end
low,high=snap(low),snap(high)
if high-low<gap then
if low+gap<=max then high=snap(low+gap)else low=snap(high-gap)end
end
local old=self.Value
self.Value={low,high}
render()
self:_fire(self.Value,silent or(old and old[1]==low and old[2]==high))
end
function element:Get()return self.Value[1],self.Value[2]end
local dragging
local function fromPoint(point)
local width=track.AbsoluteSize.X
if width<=0 then return end
local inset=5*(window.scale and window.scale.Scale or 1)
local value=min+math.clamp((point.X-Util.screenPos(track).X-inset)/math.max(1,width-inset*2),0,1)*(max-min)
if not dragging then
local low,high=element.Value[1],element.Value[2]
dragging=(math.abs(value-low)<math.abs(value-high)or(low==high and value<low))and 1 or 2
end
local next={element.Value[1],element.Value[2]}
next[dragging]=value
if dragging==1 then next[1]=math.min(value,element.Value[2]-gap)else next[2]=math.max(value,element.Value[1]+gap)end
element:Set(next)
end
hit.InputBegan:Connect(function(input)
if not Util.isPress(input)or element.Locked then return end
dragging=nil
fromPoint(Util.pointer(input))
window:_beginDrag(input,fromPoint,function()dragging=nil end)
end)
for key,object in pairs({low=lowBox,high=highBox})do
object.Focused:Connect(function()focused[key]=true object.BackgroundTransparency=0.2 render()end)
object.FocusLost:Connect(function()
focused[key]=false
object.BackgroundTransparency=1
local number=tonumber((object.Text:gsub("[^%d%.%-]","")))
if number then
local next={element.Value[1],element.Value[2]}
next[key=="low"and 1 or 2]=number
element:Set(next)
end
render()
end)
end
local default=type(cfg.Default)=="table"and cfg.Default or{min,max}
element.Value={min,max}
element:Set(default,true)
return Base.finish(element,cfg)
end
end
__modules["elements/segment"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local options={}
for _,option in ipairs(cfg.Options or cfg.Values or{})do options[#options+1]=tostring(option)end
local row,title,desc=Base.row(card,cfg,40,{})
title.Size=UDim2.new(0,110,0,cfg.Desc and 18 or 40)
if desc then desc.Size=UDim2.new(0,110,0,14)end
local strip=create("Frame",{
Name="Segments",BackgroundTransparency=1,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,120,0.5,0),
Size=UDim2.new(1,-120,0,28),Parent=row,
})
local element=Base.element(card,"Segment",cfg,row,title,desc)
local buttons,outlines={},{}
local function render(animate)
local duration=animate and 0.12 or nil
for index,option in ipairs(options)do
local selected=option==element.Value
Theme.tweenTo(buttons[index],"BackgroundColor3",selected and"selected"or"input",duration)
Theme.tweenTo(buttons[index],"TextColor3",selected and"accent"or"muted",duration)
Theme.tweenTo(outlines[index],"Color",selected and"accent"or"line",duration)
outlines[index].Transparency=selected and 0.25 or 0.65
end
end
for index,option in ipairs(options)do
local button=create("TextButton",{
Name=option,Text=option,TextSize=10,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((index-0.5)/#options,0,0.5,0),
Size=UDim2.new(1/#options,-4,0,24),TextTruncate=Enum.TextTruncate.AtEnd,Parent=strip,
})
corner(button,6)
buttons[index],outlines[index]=button,stroke(button)
button.Activated:Connect(function()if not element.Locked then element:Set(option)end end)
end
local function fit()
local stacked=row.AbsoluteSize.X>0 and row.AbsoluteSize.X<300
row.Size=UDim2.new(1,0,0,stacked and 70 or(cfg.Desc and 46 or 40))
strip.AnchorPoint=stacked and Vector2.new(0,0)or Vector2.new(0,0.5)
strip.Position=stacked and UDim2.fromOffset(0,cfg.Desc and 40 or 30)or UDim2.new(0,120,0.5,0)
strip.Size=stacked and UDim2.new(1,0,0,28)or UDim2.new(1,-120,0,28)
title.Size=UDim2.new(stacked and 1 or 0,stacked and 0 or 110,0,cfg.Desc and 18 or(stacked and 28 or 40))
end
row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
function element:Set(value,silent)
value=value~=nil and tostring(value)or nil
if value and not table.find(options,value)then return end
local changed=value~=self.Value
self.Value=value
render(true)
self:_fire(value,silent or not changed)
end
function element:Get()return self.Value end
element.Value=cfg.Default~=nil and table.find(options,tostring(cfg.Default))and tostring(cfg.Default)or options[1]
render(false)
fit()
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/slider"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner=Util.create,Util.corner
return function(card,cfg)
local window=card.window
local min,max=tonumber(cfg.Min)or 0,tonumber(cfg.Max)or 100
if max<min then min,max=max,min end
local step=tonumber(cfg.Step)or 1
local suffix=cfg.Suffix and(" "..tostring(cfg.Suffix))or""
local decimals=Util.decimals(step)
local top=cfg.Desc and 38 or 22
local row,title,desc=Base.row(card,cfg,top+18,{right=90,titleHeight=22,helpRight=84,helpY=11})
if desc then desc.Size=UDim2.new(1,0,0,14)end
local box=create("TextBox",{
Name="Value",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,1),Size=UDim2.fromOffset(78,20),
BackgroundTransparency=1,BorderSizePixel=0,Text="",TextSize=10,Font=Enum.Font.GothamMedium,
TextXAlignment=Enum.TextXAlignment.Right,ClearTextOnFocus=false,Parent=row,
})
local boxPad=Util.padding(box,0,0,0,0)
box.Focused:Connect(function()box.BackgroundTransparency=0.2 boxPad.PaddingRight=UDim.new(0,6)boxPad.PaddingLeft=UDim.new(0,6)end)
box.FocusLost:Connect(function()box.BackgroundTransparency=1 boxPad.PaddingRight=UDim.new(0,0)boxPad.PaddingLeft=UDim.new(0,0)end)
Theme.bind(box,"TextColor3","text")
Theme.bind(box,"BackgroundColor3","base")
corner(box,6)
local sideIcons=type(cfg.Icons)=="table"and cfg.Icons or nil
local inset=sideIcons and 20 or 0
local track=create("Frame",{Name="Track",Position=UDim2.new(0,inset,0,top+8),Size=UDim2.new(1,-inset*2,0,2),BorderSizePixel=0,Parent=row})
Theme.bind(track,"BackgroundColor3","buttonEdge")
corner(track,1)
local fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,Parent=track})
Theme.bind(fill,"BackgroundColor3","accent")
corner(fill,1)
local knob=create("Frame",{Name="Knob",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(10,10),BorderSizePixel=0,ZIndex=2,Parent=track})
Theme.bind(knob,"BackgroundColor3","accent")
corner(knob,5)
local reach=Util.isTouch()and 8 or 0
local hit=create("TextButton",{Name="Hit",Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.new(0,inset-6,0,top-reach),Size=UDim2.new(1,12-inset*2,0,18+reach*2),ZIndex=3,Parent=row})
local bubble=create("TextLabel",{
Name="Bubble",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,0,-6),Size=UDim2.fromOffset(0,18),AutomaticSize=Enum.AutomaticSize.X,
BorderSizePixel=0,Text="",TextSize=9,Font=Enum.Font.GothamMedium,Visible=false,ZIndex=6,Parent=knob,
})
Theme.bind(bubble,"BackgroundColor3","selected")
Theme.bind(bubble,"TextColor3","heading")
corner(bubble,5)
Util.padding(bubble,7,7,0,0)
Theme.bind(Util.stroke(bubble),"Color","buttonEdge")
local element=Base.element(card,"Slider",cfg,row,title,desc)
local focused=false
local dragging,movedWhileDragging=false,false
element.Dragging=false
local function format(value)
return(decimals>0 and string.format("%."..decimals.."f",value)or tostring(math.floor(value+0.5)))..suffix
end
local function render()
local ratio=max>min and(element.Value-min)/(max-min)or 0
fill.Size=UDim2.new(ratio,5-10*ratio,1,0)
knob.Position=UDim2.new(ratio,5-10*ratio,0.5,0)
if not focused then box.Text=format(element.Value)end
bubble.Text=format(element.Value)
end
function element:Set(value,silent)
value=tonumber(value)
if not value then render()return end
value=math.clamp(Util.round(value-min,step)+min,min,max)
if decimals>0 then value=tonumber(string.format("%."..decimals.."f",value))end
local changed=value~=self.Value
self.Value=value
render()
if changed and dragging then movedWhileDragging=true end
self:_fire(value,silent or not changed,dragging)
end
function element:Get()return self.Value end
function element:SetRange(newMin,newMax)
min,max=tonumber(newMin)or min,tonumber(newMax)or max
self:Set(self.Value)
end
local function fromPoint(point)
local width=track.AbsoluteSize.X
if width<=0 then return end
local inset=5*(window.scale and window.scale.Scale or 1)
element:Set(min+math.clamp((point.X-Util.screenPos(track).X-inset)/math.max(1,width-inset*2),0,1)*(max-min))
end
hit.InputBegan:Connect(function(input)
if not Util.isPress(input)or element.Locked then return end
bubble.Visible=cfg.Bubble~=false
dragging,movedWhileDragging=true,false
element.Dragging=true
fromPoint(Util.pointer(input))
window:_beginDrag(input,fromPoint,function()
bubble.Visible=false
dragging=false
element.Dragging=false
if movedWhileDragging then element:_fire(element.Value,false,false)end
end)
end)
if sideIcons then
local stride=step>0 and math.max(step,(max-min)/10)or(max-min)/10
for index,key in ipairs({"From","To"})do
local name=sideIcons[key]or sideIcons[index]
local icon=name and Icons.themed(row,name,13,"muted",{
Name=key.."Icon",AnchorPoint=Vector2.new(index==1 and 0 or 1,0.5),Position=UDim2.new(index==1 and 0 or 1,0,0,top+9),
})
if icon then
local click=create("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,6,1,6),Position=UDim2.fromOffset(-3,-3),ZIndex=4,Parent=icon})
click.Activated:Connect(function()
if element.Locked then return end
element:Set(element.Value+(index==1 and-stride or stride))
end)
click.MouseEnter:Connect(function()Theme.tweenTo(icon,"ImageColor3","heading",0.1)end)
click.MouseLeave:Connect(function()Theme.tweenTo(icon,"ImageColor3","muted",0.1)end)
end
end
end
box.Focused:Connect(function()focused=true end)
box.FocusLost:Connect(function()
focused=false
local number=tonumber((box.Text:gsub("[^%d%.%-]","")))
if number then element:Set(number)else render()end
render()
end)
element.Value=math.clamp(tonumber(cfg.Default)or min,min,max)
render()
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/stat"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local SIZE,HEIGHT=18,22
local FONT=Enum.Font.GothamBold
local function group(text,separator)
if separator==""then return text end
local sign,whole,rest=text:match("^([%-]?)(%d+)(.*)$")
if not whole then return text end
whole=whole:reverse():gsub("(%d%d%d)","%1"..separator:reverse()):reverse()
if whole:sub(1,#separator)==separator then whole=whole:sub(#separator+1)end
return sign..whole..rest
end
return function(card,cfg)
local hasIcon=cfg.Icon and Icons.Get(cfg.Icon)
local x=hasIcon and 44 or 0
local holder=create("Frame",{Name=tostring(cfg.Title or"Stat"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,44),LayoutOrder=card:_order(),Parent=card.body})
if hasIcon then
local tile=create("Frame",{Name="IconTile",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.fromOffset(34,34),BorderSizePixel=0,Parent=holder})
Theme.bind(tile,"BackgroundColor3","accentDeep")
corner(tile,9)
local edge=stroke(tile,nil,0.6)
Theme.bind(edge,"Color","accent")
Icons.themed(tile,cfg.Icon,16,"accent",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
end
local title=label(holder,tostring(cfg.Title or""),9,{Name="Title",Position=UDim2.fromOffset(x,2),Size=UDim2.new(1,-x-80,0,14),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3","muted")
local digits=create("Frame",{Name="Digits",BackgroundTransparency=1,Position=UDim2.fromOffset(x,17),Size=UDim2.new(1,-x-80,0,HEIGHT),ClipsDescendants=true,Parent=holder})
Util.list(digits,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
local chip=create("Frame",{Name="Delta",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(0,20),AutomaticSize=Enum.AutomaticSize.X,BorderSizePixel=0,Visible=false,Parent=holder})
corner(chip,10)
Util.list(chip,4,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
Util.padding(chip,7,8,0,0)
local chipIcon=Icons.themed(chip,"trending-up",11,"success",{Name="Arrow",LayoutOrder=1})
local chipText=label(chip,"",9,{Name="Text",Size=UDim2.fromOffset(0,20),AutomaticSize=Enum.AutomaticSize.X,Font=Enum.Font.GothamMedium,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2})
local element=Base.element(card,"Stat",{},holder,title,nil)
local decimals=math.max(0,math.floor(tonumber(cfg.Decimals)or 0))
local separator=cfg.Separator==nil and","or tostring(cfg.Separator)
local digitWidth=math.max(8,Util.textWidth("0",SIZE,FONT)+2)
local function format(value)
if type(cfg.Format)=="function"then
local ok,result=pcall(cfg.Format,value)
if ok then return tostring(result)end
end
local text=decimals>0 and string.format("%."..decimals.."f",value)or tostring(math.floor(value+0.5))
return tostring(cfg.Prefix or"")..group(text,separator)..tostring(cfg.Suffix or"")
end
local columns,shape={},nil
local function build(text)
for _,column in ipairs(columns)do column.frame:Destroy()end
columns={}
for index=1,#text do
local char=text:sub(index,index)
local digit=tonumber(char)
if digit then
local frame=create("Frame",{Name="Digit",BackgroundTransparency=1,Size=UDim2.fromOffset(digitWidth,HEIGHT),ClipsDescendants=true,LayoutOrder=index,Parent=digits})
local strip=create("Frame",{Name="Strip",BackgroundTransparency=1,Position=UDim2.fromOffset(0,-digit*HEIGHT),Size=UDim2.fromOffset(digitWidth,HEIGHT*10),Parent=frame})
for n=0,9 do
local glyph=label(strip,tostring(n),SIZE,{Name=tostring(n),Position=UDim2.fromOffset(0,n*HEIGHT),Size=UDim2.fromOffset(digitWidth,HEIGHT),Font=FONT,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.None})
Theme.bind(glyph,"TextColor3","heading")
end
columns[index]={frame=frame,strip=strip,digit=digit}
else
local frame=label(digits,char,SIZE,{Name="Char",Size=UDim2.fromOffset(char==" "and 4 or 0,HEIGHT),AutomaticSize=char==" "and Enum.AutomaticSize.None or Enum.AutomaticSize.X,Font=FONT,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.None,LayoutOrder=index})
Theme.bind(frame,"TextColor3","heading")
columns[index]={frame=frame,char=char}
end
end
end
local function shapeOf(text)return(text:gsub("%d","#"))end
local function show(text,animate)
local newShape=shapeOf(text)
if newShape~=shape then
shape=newShape
build(text)
return
end
for index=1,#text do
local column,digit=columns[index],tonumber(text:sub(index,index))
if column and column.strip and digit and digit~=column.digit then
column.digit=digit
local target=UDim2.fromOffset(0,-digit*HEIGHT)
if animate then
Util.tween(column.strip,0.35+(#text-index)*0.04,{Position=target},Enum.EasingStyle.Quint)
else
column.strip.Position=target
end
end
end
end
local mode=cfg.Delta==nil and"percent"or cfg.Delta
local function renderDelta(old,new)
if not mode or old==nil or old==new then return end
local change=new-old
local good=(change>0)~=(cfg.Invert==true)
local role=good and"success"or"danger"
local text
if mode=="absolute"then
text=(change>0 and"+"or"")..format(change):gsub("^"..tostring(cfg.Prefix or""):gsub("%p","%%%0"),"")
else
if old==0 then text=change>0 and"+new"or"-"else text=string.format("%+.1f%%",change/math.abs(old)*100)end
end
chipText.Text=text
Theme.bind(chip,"BackgroundColor3",role)
chip.BackgroundTransparency=0.86
Theme.bind(chipText,"TextColor3",role)
if chipIcon then
Icons.Apply(chipIcon,change>0 and"trending-up"or"trending-down")
Theme.bind(chipIcon,"ImageColor3",role)
end
chip.Visible=true
end
function element:Set(value,silent)
value=tonumber(value)
if not value then return end
local old=self.Value
self.Value=value
show(format(value),old~=nil and not silent)
renderDelta(old,value)
end
function element:Add(amount)self:Set((self.Value or 0)+(tonumber(amount)or 0))end
function element:Get()return self.Value end
function element:SetTitle(text)title.Text=tostring(text)end
element:Set(tonumber(cfg.Value or cfg.Default)or 0,true)
return element
end
end
__modules["elements/stepper"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
return function(card,cfg)
local min,max=tonumber(cfg.Min)or 0,tonumber(cfg.Max)or 10
if max<min then min,max=max,min end
local step=tonumber(cfg.Step)or 1
if step<=0 then step=1 end
local decimals=Util.decimals(step)
local suffix=cfg.Suffix and(" "..tostring(cfg.Suffix))or""
local row,title,desc=Base.row(card,cfg,cfg.Desc and 40 or 30,{right=106,helpRight=100})
local box=create("Frame",{Name="Stepper",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(96,24),BorderSizePixel=0,Parent=row})
Theme.bind(box,"BackgroundColor3","input")
corner(box,6)
Theme.bind(stroke(box),"Color","buttonEdge")
local function sideButton(name,icon,side)
local button=create("TextButton",{
Name=name,Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundTransparency=1,
AnchorPoint=Vector2.new(side,0.5),Position=UDim2.new(side,0,0.5,0),Size=UDim2.fromOffset(24,24),Parent=box,
})
Theme.bind(button,"BackgroundColor3","hover")
corner(button,6)
local image=Icons.themed(button,icon,12,"text",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
button.MouseEnter:Connect(function()Util.tween(button,0.1,{BackgroundTransparency=0})if image then Theme.tweenTo(image,"ImageColor3","heading",0.1)end end)
button.MouseLeave:Connect(function()Util.tween(button,0.1,{BackgroundTransparency=1})if image then Theme.tweenTo(image,"ImageColor3","text",0.1)end end)
return button,image
end
local minus=sideButton("Minus","minus",0)
local plus=sideButton("Plus","plus",1)
local value=create("TextBox",{
Name="Value",BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
Size=UDim2.new(1,-48,1,0),Text="",TextSize=10,Font=Enum.Font.GothamMedium,ClearTextOnFocus=false,
TextTruncate=Enum.TextTruncate.AtEnd,Parent=box,
})
Theme.bind(value,"TextColor3","heading")
Theme.bind(value,"PlaceholderColor3","muted")
local element=Base.element(card,"Stepper",cfg,row,title,desc)
local focused=false
local function format(number)
return(decimals>0 and string.format("%."..decimals.."f",number)or tostring(math.floor(number+0.5)))..suffix
end
local function render()
if not focused then value.Text=format(element.Value)end
minus.Active,plus.Active=element.Value>min,element.Value<max
for _,button in ipairs({minus,plus})do
local icon=button:FindFirstChildWhichIsA("ImageLabel")
if icon then icon.ImageTransparency=button.Active and 0 or 0.6 end
end
end
function element:Set(number,silent)
number=tonumber(number)
if not number or number~=number then render()return end
number=math.clamp(Util.round(number-min,step)+min,min,max)
if decimals>0 then number=tonumber(string.format("%."..decimals.."f",number))end
local changed=number~=self.Value
self.Value=number
render()
self:_fire(number,silent or not changed)
end
function element:Get()return self.Value end
function element:SetRange(newMin,newMax)
min,max=tonumber(newMin)or min,tonumber(newMax)or max
self:Set(self.Value)
end
local function hold(button,direction)
local holding=0
button.InputBegan:Connect(function(input)
if not Util.isPress(input)or element.Locked then return end
holding=holding+1
local mine=holding
element:Set(element.Value+step*direction)
task.spawn(function()
task.wait(0.4)
local delay=0.12
while holding==mine and button.Parent and not element.Locked do
local before=element.Value
element:Set(element.Value+step*direction)
if element.Value==before then break end
task.wait(delay)
delay=math.max(0.03,delay*0.85)
end
end)
end)
button.InputEnded:Connect(function(input)if Util.isPress(input)then holding=holding+1 end end)
button.MouseLeave:Connect(function()holding=holding+1 end)
end
hold(minus,-1)
hold(plus,1)
value.Focused:Connect(function()focused=true value.Text=format(element.Value):gsub(suffix:gsub("%p","%%%0").."$","")end)
value.FocusLost:Connect(function()
focused=false
local number=tonumber((value.Text:gsub("[^%d%.%-]","")))
if number then element:Set(number)else render()end
render()
end)
element.Value=math.clamp(tonumber(cfg.Default)or min,min,max)
render()
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/swatches"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local PRESETS={
{"Neutral",Color3.fromRGB(177,178,183)},{"Blue",Color3.fromRGB(61,151,219)},
{"Red",Color3.fromRGB(220,110,110)},{"Purple",Color3.fromRGB(165,125,230)},
{"Pink",Color3.fromRGB(225,120,180)},{"Green",Color3.fromRGB(110,200,130)},
{"Orange",Color3.fromRGB(215,170,105)},{"Cyan",Color3.fromRGB(100,200,210)},
}
return function(card,cfg)
local colors=cfg.Colors or PRESETS
local maxColumns=math.max(1,tonumber(cfg.Columns)or 4)
local columns=maxColumns
local rowsCount=math.ceil(#colors/columns)
local top=(cfg.Title and 20 or 0)+(cfg.Desc and 16 or 0)+(cfg.Title and 4 or 0)
local holder=create("Frame",{Name=tostring(cfg.Title or"Swatches"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,top+rowsCount*34),LayoutOrder=card:_order(),Parent=card.body})
local title,desc
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,0,0,20)})
Theme.bind(title,"TextColor3","text")
end
if cfg.Desc then
desc=label(holder,tostring(cfg.Desc),9,{Name="Desc",Position=UDim2.fromOffset(0,cfg.Title and 20 or 0),Size=UDim2.new(1,0,0,14)})
Theme.bind(desc,"TextColor3","muted")
end
local grid=create("Frame",{Name="Grid",BackgroundTransparency=1,Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,1,-top),Parent=holder})
local element=Base.element(card,"Swatches",cfg,holder,title,desc)
local entries,byName={},{}
local function render()
for _,entry in ipairs(entries)do
local on=entry.name==element.Value
Theme.tweenTo(entry.button,"BackgroundColor3",on and"selected"or"card",0.1)
Theme.tweenTo(entry.text,"TextColor3",on and"heading"or"muted",0.1)
entry.outline.Transparency=on and 0.3 or 1
end
end
for index,item in ipairs(colors)do
local name,color=tostring(item[1]or item.Name),item[2]or item.Color
local button=create("TextButton",{Name=name,Text="",AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=index,Parent=grid})
corner(button,6)
local outline=stroke(button,Color3.new(1,1,1),1)
Theme.bind(outline,"Color","accent")
local dot=create("Frame",{Name="Dot",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),Size=UDim2.fromOffset(14,14),BorderSizePixel=0,BackgroundColor3=color,Parent=button})
corner(dot,4)
local text=label(button,name,10,{Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-32,1,0)})
local entry={name=name,color=color,button=button,text=text,outline=outline}
entries[#entries+1]=entry
byName[name]=entry
Util.hoverPop(button,1.04)
button.MouseEnter:Connect(function()
if element.Value~=name then
Theme.tweenTo(button,"BackgroundColor3","input",0.1)
Theme.tweenTo(text,"TextColor3","heading",0.1)
end
end)
button.MouseLeave:Connect(render)
button.Activated:Connect(function()if not element.Locked then element:Set(name)end end)
end
local function place()
local width=holder.AbsoluteSize.X
columns=width>0 and math.clamp(math.floor((width+6)/90),2,maxColumns)or maxColumns
columns=math.min(columns,math.max(1,#entries))
for index,entry in ipairs(entries)do
local column,line=(index-1)%columns,(index-1)//columns
entry.button.Position=UDim2.new(column/columns,column==0 and 0 or 3,0,line*34)
entry.button.Size=UDim2.new(1/columns,-6+(column==0 and 3 or 0)+(column==columns-1 and 3 or 0),0,28)
end
holder.Size=UDim2.new(1,0,0,top+math.ceil(#entries/columns)*34)
end
holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
local before=columns
local width=holder.AbsoluteSize.X
local want=width>0 and math.min(math.clamp(math.floor((width+6)/90),2,maxColumns),#entries)or maxColumns
if want~=before then place()end
end)
place()
function element:Set(name,silent)
if typeof(name)=="Color3"then
for _,entry in ipairs(entries)do if entry.color==name then name=entry.name break end end
end
if typeof(name)=="Color3"then
self.Value,self.Color=nil,name
render()
return
end
local entry=byName[tostring(name)]
if not entry then return end
local changed=entry.name~=self.Value
self.Value=entry.name
self.Color=entry.color
render()
if self.Flag then card.window.Lib.Flags[self.Flag]=entry.name card.window:_flagChanged(self.Flag)end
if not silent and changed then
self:_call(cfg.Callback,entry.color,entry.name)
for _,callback in ipairs(self._changed)do self:_call(callback,entry.color,entry.name)end
end
end
function element:Get()return self.Value,self.Color end
function element:SetColor(name,color)
for _,entry in ipairs(entries)do
if entry.name==name and typeof(color)=="Color3"then
entry.color=color
local dot=entry.button:FindFirstChild("Dot")
if dot then dot.BackgroundColor3=color end
if self.Value==name then self.Color=color end
end
end
end
element:Set(cfg.Default or(entries[1]and entries[1].name),true)
return Base.finish(element,cfg)
end
end
__modules["elements/table"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local ROW=24
return function(card,cfg)
local columns,fixed,open={},0,0
for index,spec in ipairs(cfg.Columns or{"Value"})do
if type(spec)~="table"then spec={Title=spec}end
local width=tonumber(spec.Width)
columns[index]={title=tostring(spec.Title or("Column "..index)),width=width,align=spec.Align=="Right"and Enum.TextXAlignment.Right or(spec.Align=="Center"and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left)}
if width then fixed=fixed+width else open=open+1 end
end
for _,column in ipairs(columns)do
if not column.width then column.width=open>0 and math.max(0.05,(1-fixed)/open)or 0.1 end
end
local height=tonumber(cfg.Height)or 160
local top=(cfg.Title and 22 or 0)+(cfg.Search and 30 or 0)
local holder=create("Frame",{Name=tostring(cfg.Title or"Table"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,top+height),LayoutOrder=card:_order(),Parent=card.body})
local title
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,-80,0,20)})
Theme.bind(title,"TextColor3","text")
end
local count=label(holder,"",9,{Name="Count",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(80,20),TextXAlignment=Enum.TextXAlignment.Right})
Theme.bind(count,"TextColor3","muted")
local search
if cfg.Search then
search=create("TextBox",{
Name="Search",Position=UDim2.fromOffset(0,cfg.Title and 22 or 0),Size=UDim2.new(1,0,0,24),BorderSizePixel=0,
Text="",PlaceholderText="Search...",TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
ClearTextOnFocus=false,Parent=holder,
})
Theme.bind(search,"BackgroundColor3","input")
Theme.bind(search,"TextColor3","text")
Theme.bind(search,"PlaceholderColor3","muted")
corner(search,6)
Theme.bind(stroke(search),"Color","buttonEdge")
Util.padding(search,8,8,0,0)
end
local box=create("Frame",{Name="Box",Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,ClipsDescendants=true,Parent=holder})
Theme.bind(box,"BackgroundColor3","base")
corner(box,7)
Theme.bind(stroke(box),"Color","line")
local head=create("Frame",{Name="Head",Size=UDim2.new(1,0,0,ROW),BorderSizePixel=0,Parent=box})
Theme.bind(head,"BackgroundColor3","input")
local headLine=create("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,Parent=head})
Theme.bind(headLine,"BackgroundColor3","line")
local body=create("ScrollingFrame",{
Name="Rows",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,ROW),Size=UDim2.new(1,0,1,-ROW),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=box,
})
Theme.bind(body,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(body)
Util.fitCanvas(body,Util.list(body,0))
local empty=label(box,cfg.Empty or"No rows",10,{Name="Empty",Position=UDim2.fromOffset(0,ROW),Size=UDim2.new(1,0,1,-ROW),TextXAlignment=Enum.TextXAlignment.Center})
Theme.bind(empty,"TextColor3","muted")
local element=Base.element(card,"Table",{},holder,title,nil)
local rows={}
local sortColumn,descending=nil,false
local headers={}
local function starts()
local out,x={},0
for index,column in ipairs(columns)do out[index]=x x=x+column.width end
return out
end
local function cell(parent,index,text,x,bold)
local column=columns[index]
local object=label(parent,tostring(text==nil and""or text),10,{
Name="Cell"..index,Position=UDim2.new(x,8,0,0),Size=UDim2.new(column.width,-16,1,0),
TextXAlignment=column.align,Font=bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
})
return object
end
local sortable=cfg.Sortable~=false
for index,column in ipairs(columns)do
local x=starts()[index]
local button=create("TextButton",{Name=column.title,Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromScale(x,0),Size=UDim2.new(column.width,0,1,0),Parent=head})
local text=label(button,column.title,9,{Name="Text",Position=UDim2.fromOffset(8,0),Size=UDim2.new(1,-16,1,0),TextXAlignment=column.align,Font=Enum.Font.GothamMedium})
Theme.bind(text,"TextColor3","muted")
local arrow=Icons.themed(button,"chevron-down",10,"accent",{Name="Arrow",AnchorPoint=Vector2.new(column.align==Enum.TextXAlignment.Right and 0 or 1,0.5),Position=UDim2.new(column.align==Enum.TextXAlignment.Right and 0 or 1,column.align==Enum.TextXAlignment.Right and 2 or-2,0.5,0),Visible=false})
headers[index]={text=text,arrow=arrow}
if sortable then
button.MouseEnter:Connect(function()Theme.tweenTo(text,"TextColor3","heading",0.1)end)
button.MouseLeave:Connect(function()Theme.tweenTo(text,"TextColor3",sortColumn==index and"accent"or"muted",0.1)end)
button.Activated:Connect(function()element:Sort(index,sortColumn==index and not descending)end)
end
end
local function matches(row)
local query=search and search.Text:lower()or""
if query==""then return true end
for index=1,#columns do
local value=row[index]
if value~=nil and tostring(value):lower():find(query,1,true)then return true end
end
return false
end
local function ordered()
local list={}
for index,row in ipairs(rows)do list[#list+1]={row=row,index=index}end
if sortColumn then
table.sort(list,function(a,b)
local x,y=a.row[sortColumn],b.row[sortColumn]
local emptyX,emptyY=x==nil or x=="",y==nil or y==""
if emptyX or emptyY then
if emptyX and emptyY then return a.index<b.index end
return emptyY
end
if tostring(x)==tostring(y)then return a.index<b.index end
local nx,ny=tonumber(x),tonumber(y)
local less
if nx and ny then less=nx<ny
elseif nx or ny then less=nx~=nil
else less=tostring(x):lower()<tostring(y):lower()end
if descending then return not less end
return less
end)
end
return list
end
local drawn={}
local function render()
for _,object in ipairs(drawn)do object:Destroy()end
drawn={}
local x=starts()
local shown=0
for position,item in ipairs(ordered())do
if matches(item.row)then
shown=shown+1
local line=create("TextButton",{Name="Row"..item.index,Text="",AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.new(1,0,0,ROW),LayoutOrder=position,Parent=body})
Theme.bind(line,"BackgroundColor3","card")
local stripe=shown%2==0 and 0.4 or 1
line.BackgroundTransparency=stripe
for index=1,#columns do
local object=cell(line,index,item.row[index],x[index],index==1)
Theme.bind(object,"TextColor3",index==1 and"heading"or"text")
end
line.MouseEnter:Connect(function()Theme.tweenTo(line,"BackgroundColor3","hover",0.08)line.BackgroundTransparency=0 end)
line.MouseLeave:Connect(function()Theme.tweenTo(line,"BackgroundColor3","card",0.08)line.BackgroundTransparency=stripe end)
if cfg.OnRowClick then
local rowData,rowIndex=item.row,item.index
line.Activated:Connect(function()element:_call(cfg.OnRowClick,rowData,rowIndex)end)
end
drawn[#drawn+1]=line
end
end
empty.Visible=shown==0
empty.Text=#rows>0 and"No matches"or(cfg.Empty or"No rows")
count.Text=(shown==#rows)and(#rows..(#rows==1 and" row"or" rows"))or(shown.." / "..#rows)
for index,header in ipairs(headers)do
local on=sortColumn==index
Theme.bind(header.text,"TextColor3",on and"accent"or"muted")
if header.arrow then
header.arrow.Visible=on
header.arrow.Rotation=descending and 0 or 180
end
end
end
local function copy(row)
local out={}
row=row or{}
for index=1,math.max(#columns,#row)do out[index]=row[index]end
return out
end
function element:SetRows(list)
rows={}
for _,row in ipairs(list or{})do rows[#rows+1]=copy(row)end
render()
end
function element:AddRow(row)rows[#rows+1]=copy(row)render()return#rows end
function element:RemoveRow(index)if rows[index]then table.remove(rows,index)render()end end
function element:UpdateRow(index,row)if rows[index]then rows[index]=copy(row)render()end end
function element:Clear()rows={}render()end
function element:GetRows()return rows end
function element:Sort(column,desc)
if column~=nil and not columns[column]then
for index,item in ipairs(columns)do if item.title==column then column=index break end end
end
sortColumn=columns[column]and column or nil
descending=desc==true
render()
end
function element:Get()return rows end
function element:Set(list)self:SetRows(list)end
if search then search:GetPropertyChangedSignal("Text"):Connect(render)end
element:SetRows(cfg.Rows)
if cfg.SortBy then element:Sort(cfg.SortBy,cfg.Descending)end
return element
end
end
__modules["elements/textarea"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(card,cfg)
local height=math.max(40,tonumber(cfg.Height)or 80)
local maxLength=tonumber(cfg.MaxLength)
local top=(cfg.Title and 20 or 0)+(cfg.Desc and 16 or 0)+(cfg.Title and 4 or 0)
local holder=create("Frame",{Name=tostring(cfg.Title or"TextArea"),BackgroundTransparency=1,Size=UDim2.new(1,0,0,top+height),LayoutOrder=card:_order(),Parent=card.body})
local title,desc
if cfg.Title then
title=label(holder,tostring(cfg.Title),11,{Name="Title",Size=UDim2.new(1,maxLength and-70 or 0,0,20)})
Theme.bind(title,"TextColor3",cfg.Risky and"danger"or"text")
end
if cfg.Desc then
desc=label(holder,tostring(cfg.Desc),9,{Name="Desc",Position=UDim2.fromOffset(0,cfg.Title and 20 or 0),Size=UDim2.new(1,0,0,14)})
Theme.bind(desc,"TextColor3","muted")
end
local counter
if maxLength then
counter=label(holder,"",9,{Name="Counter",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(70,20),TextXAlignment=Enum.TextXAlignment.Right})
Theme.bind(counter,"TextColor3","muted")
end
local box=create("TextBox",{
Name="Box",Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,Text="",
PlaceholderText=tostring(cfg.Placeholder or""),TextSize=10,Font=Enum.Font.Gotham,MultiLine=true,TextWrapped=true,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,ClipsDescendants=true,
Parent=holder,
})
Theme.bind(box,"BackgroundColor3","input")
Theme.bind(box,"TextColor3","text")
Theme.bind(box,"PlaceholderColor3","muted")
corner(box,7)
local outline=stroke(box)
Theme.bind(outline,"Color","buttonEdge")
Util.padding(box,10,10,8,8)
local element=Base.element(card,"TextArea",cfg,holder,title,desc)
local function count()
if counter then
counter.Text=#box.Text.." / "..maxLength
Theme.bind(counter,"TextColor3",#box.Text>=maxLength and"warning"or"muted")
end
end
function element:Set(text,silent)
text=tostring(text==nil and""or text)
if maxLength and#text>maxLength then text=text:sub(1,maxLength)end
local changed=text~=self.Value
self.Value=text
if box.Text~=text then box.Text=text end
count()
self._failed=false
self:_fire(text,silent or not changed)
if changed and not silent then self:_accepted("success")end
end
function element:Get()return self.Value end
box:GetPropertyChangedSignal("Text"):Connect(function()
if maxLength and#box.Text>maxLength then box.Text=box.Text:sub(1,maxLength)return end
count()
if cfg.Finished==false then element:Set(box.Text)end
end)
box.Focused:Connect(function()Theme.tweenTo(outline,"Color","accent",0.1)end)
box.FocusLost:Connect(function()
Theme.tweenTo(outline,"Color","buttonEdge",0.1)
element:Set(box.Text)
end)
element:Set(cfg.Default or"",true)
if cfg.Locked then box.TextEditable=false end
return Base.finish(element,cfg)
end
end
__modules["elements/toggle"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner=Util.create,Util.corner
return function(card,cfg)
local window=card.window
local bindable=cfg.Bindable or cfg.Bind~=nil
local row,title,desc=Base.row(card,cfg,cfg.Desc and 46 or 36,{button=true,right=50,helpRight=44})
local switch=create("TextButton",{
Name="Switch",Text="",AutoButtonColor=false,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(34,18),Parent=row,
})
corner(switch,9)
local rim=Util.stroke(switch,nil,0.18)
local knob=create("Frame",{Name="Knob",Position=UDim2.fromOffset(2,2),Size=UDim2.fromOffset(14,14),BorderSizePixel=0,Parent=switch})
corner(knob,7)
if cfg.Marker then
local marker=create("Frame",{Name="Marker",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.fromOffset(3,24),BorderSizePixel=0,BackgroundTransparency=0.15,Parent=row})
Theme.bind(marker,"BackgroundColor3","accent")
corner(marker,2)
local icon=row:FindFirstChild("RowIcon")
if icon then icon.Position=UDim2.new(0,12,icon.Position.Y.Scale,icon.Position.Y.Offset)end
title.Position=UDim2.new(0,title.Position.X.Offset+12,0,title.Position.Y.Offset)
if desc then desc.Position=UDim2.fromOffset(desc.Position.X.Offset+12,desc.Position.Y.Offset)end
end
if cfg.Badge then
local text=tostring(cfg.Badge)
local width=Util.textWidth(text,9,Enum.Font.GothamMedium)+16
local titleWidth=Util.textWidth(tostring(cfg.Title or""),11,Enum.Font.Gotham)
local badge=create("Frame",{
Name="Badge",AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,title.Position.X.Offset+titleWidth+10,0,title.Position.Y.Offset+title.Size.Y.Offset/2),
Size=UDim2.fromOffset(width,18),BorderSizePixel=0,Parent=row,
})
Theme.bind(badge,"BackgroundColor3","input")
corner(badge,6)
Theme.bind(Util.stroke(badge,nil,0.45),"Color","buttonEdge")
local badgeText=Util.label(badge,text,9,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamMedium})
Theme.bind(badgeText,"TextColor3","muted")
end
local element=Base.element(card,"Toggle",cfg,row,title,desc)
element.Value=cfg.Default==true
local function render(animate)
local on=element.Value
local duration=animate and 0.15 or nil
Theme.tweenTo(switch,"BackgroundColor3",on and"toggleOn"or"buttonEdge",duration)
Theme.bind(knob,"BackgroundColor3","knob")
Theme.tweenTo(rim,"Color",on and"accent"or"line",duration)
rim.Transparency=on and 0.6 or 0.18
local position=UDim2.fromOffset(on and 18 or 2,2)
if animate then Util.tween(knob,0.15,{Position=position})else knob.Position=position end
end
function element:Set(value,silent)
value=value==true
local changed=value~=self.Value
self.Value=value
render(true)
if changed then self:_fire(value,silent)else self:_fire(value,true)end
end
function element:Get()return self.Value end
local tag
function element:SetBind(key)
key=Util.toKey(key)
self.BindKey=key
window:_bind(self,key)
if tag then
tag.Text=key and("["..Util.keyName(key).."]")or""
tag.Visible=key~=nil
local reserve=(key and 100 or 50)+(cfg.Help and 16 or 0)
title.Size=UDim2.new(1,-reserve,0,title.Size.Y.Offset)
if desc then desc.Size=UDim2.new(1,-reserve,0,14)end
end
end
element.BindMode=cfg.BindMode=="Hold"and"Hold"or"Toggle"
function element:SetBindMode(mode)self.BindMode=mode=="Hold"and"Hold"or"Toggle"end
function element:_onBind()
if self.Locked then return end
if self.BindMode=="Hold"then self._held=true self:Set(true)else self:Set(not self.Value)end
end
function element:_onRelease()
if self.BindMode=="Hold"and self._held then self._held=false self:Set(false)end
end
if bindable then
tag=Util.label(row,"",9,{
Name="Bind",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,cfg.Help and-62 or-42,0.5,0),Size=UDim2.fromOffset(48,18),
TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,Visible=false,
})
Theme.bind(tag,"TextColor3","muted")
element._keyLabel=tag
row.MouseButton2Click:Connect(function()
if element.Locked then return end
tag.Text,tag.Visible="[...]",true
title.Size=UDim2.new(1,-(100+(cfg.Help and 16 or 0)),0,title.Size.Y.Offset)
window._capture=function(key)
if key==Enum.KeyCode.Escape or key==window.key then element:SetBind(element.BindKey)
elseif key==Enum.KeyCode.Backspace then element:SetBind(nil)
else element:SetBind(key)end
end
end)
element:SetBind(cfg.Bind)
function element:_save()return{Value=self.Value,Bind=self.BindKey and self.BindKey.Name or nil}end
function element:_load(data)
if type(data)=="table"then self:SetBind(data.Bind)self:Set(data.Value)else self:Set(data)end
end
end
local function flip()if not element.Locked then element:Set(not element.Value)end end
row.Activated:Connect(flip)
switch.Activated:Connect(flip)
row.MouseEnter:Connect(function()Theme.tweenTo(title,"TextColor3",cfg.Risky and"danger"or"heading",0.12)end)
row.MouseLeave:Connect(function()Theme.tweenTo(title,"TextColor3",cfg.Risky and"danger"or"text",0.12)end)
render(false)
element:_fire(element.Value,true)
return Base.finish(element,cfg)
end
end
__modules["elements/viewport"]=function()
local Util=require("util")
local Theme=require("theme")
local Base=require("elements/base")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(card,cfg)
local window=card.window
local height=tonumber(cfg.Height)or 170
local holder=create("Frame",{Name=tostring(cfg.Name or"Viewport"),Size=UDim2.new(1,0,0,height),BorderSizePixel=0,LayoutOrder=card:_order(),Parent=card.body})
Theme.bind(holder,"BackgroundColor3","base")
corner(holder,8)
Theme.bind(stroke(holder),"Color","line")
local view=create("ViewportFrame",{
Name="View",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(150,150,155),
LightColor=Color3.fromRGB(255,255,255),LightDirection=Vector3.new(-1,-1,-0.6),Parent=holder,
})
corner(view,8)
local camera=Instance.new("Camera")
camera.FieldOfView=40
camera.Parent=view
view.CurrentCamera=camera
local world=Instance.new("WorldModel")
world.Parent=view
local empty=label(holder,"No object",10,{Name="Empty",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center})
Theme.bind(empty,"TextColor3","muted")
local element=Base.element(card,"Viewport",{},holder,nil,nil)
local center,radius=Vector3.zero,5
local yaw,pitch,zoom=math.rad(25),math.rad(-12),1
local spin=cfg.Spin==true
local function place()
local distance=(tonumber(cfg.Distance)or radius/math.tan(math.rad(camera.FieldOfView/2))*1.15)*zoom
local rotation=CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)
camera.CFrame=CFrame.new(center)*rotation*CFrame.new(0,0,distance)
camera.Focus=CFrame.new(center)
end
function element:SetObject(object)
world:ClearAllChildren()
self.Value=object
empty.Visible=object==nil
if not object then return end
local ok,copy=pcall(function()
local archivable=object.Archivable
object.Archivable=true
local clone=object:Clone()
object.Archivable=archivable
return clone
end)
if not ok or not copy then empty.Text="Cannot preview"empty.Visible=true return end
for _,d in ipairs(copy:GetDescendants())do
if d:IsA("LuaSourceContainer")then d:Destroy()elseif d:IsA("BasePart")then d.Anchored=true end
end
if copy:IsA("BasePart")then copy.Anchored=true end
copy.Parent=world
local okBox,cf,size=pcall(function()
if copy:IsA("Model")then return copy:GetBoundingBox()end
return copy.CFrame,copy.Size
end)
if okBox then center,radius=cf.Position,math.max(size.Magnitude/2,0.5)end
place()
end
function element:SetSpin(on)spin=on==true end
if cfg.Interactive~=false then
local hit=create("TextButton",{Name="Drag",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=3,Parent=holder})
hit.InputBegan:Connect(function(input)
if not Util.isPress(input)then return end
local last=Util.pointer(input)
window:_beginDrag(input,function(point)
local delta=point-last
last=point
yaw=yaw-delta.X*0.012
pitch=math.clamp(pitch-delta.Y*0.01,-1.3,1.3)
place()
end)
end)
hit.InputChanged:Connect(function(input)
if input.UserInputType==Enum.UserInputType.MouseWheel then
zoom=math.clamp(zoom*(input.Position.Z>0 and 0.9 or 1.1),0.4,3)
place()
end
end)
end
window.maid:connect(Util.Services.RunService.Heartbeat,function(dt)
if spin and holder.Parent and holder.AbsoluteSize.X>0 then yaw=yaw+(dt or 0.016)*0.6 place()end
end)
element:SetObject(cfg.Object)
return element
end
end
__modules["font"]=function()
local UIFont={current="Gotham",guis={}}
UIFont.order={"Gotham","BuilderSans","Montserrat","Ubuntu","Roboto","SourceSans","Nunito","Arimo"}
local function isText(object)
return object:IsA("TextLabel")or object:IsA("TextButton")or object:IsA("TextBox")
end
local function familyOf(name)
local ok,face=pcall(function()return Font.fromEnum(Enum.Font[name])end)
return ok and face and face.Family or nil
end
local function apply(object,target)
if not target or not isText(object)then return end
pcall(function()
local face=object.FontFace
if face.Family~=target then object.FontFace=Font.new(target,face.Weight,face.Style)end
end)
end
function UIFont.refresh()
local target=familyOf(UIFont.current)
for gui in pairs(UIFont.guis)do
if gui.Parent then
for _,object in ipairs(gui:GetDescendants())do apply(object,target)end
else
UIFont.guis[gui]=nil
end
end
end
function UIFont.set(name)
name=tostring(name or"Gotham")
if not table.find(UIFont.order,name)or not familyOf(name)then return false end
UIFont.current=name
UIFont.refresh()
return true
end
function UIFont.register(gui,maid)
if UIFont.guis[gui]then return end
UIFont.guis[gui]=true
local connection=gui.DescendantAdded:Connect(function(object)
if UIFont.current=="Gotham"or not isText(object)then return end
task.defer(function()
if object.Parent then apply(object,familyOf(UIFont.current))end
end)
end)
if maid then maid:give(connection)end
if UIFont.current~="Gotham"then task.defer(UIFont.refresh)end
end
return UIFont
end
__modules["gate"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local UIFont=require("font")
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
local Gate={}
local function trim(text)return(tostring(text or""):gsub("^%s+",""):gsub("%s+$",""))end
local function check(spec,key)
key=trim(key)
if key==""then return false,"Enter a key"end
if type(spec.Check)=="function"then
local ran,ok,message=pcall(spec.Check,key)
if not ran then return false,"The key could not be checked"end
return ok==true,message
end
for _,valid in ipairs(spec.Keys or{})do
if key==trim(valid)then return true end
end
return false,"Wrong key"
end
Gate.check=check
function Gate.file(folder)return folder.."/key.txt"end
function Gate.run(Lib,cfg)
local spec=cfg.KeySystem
local folder=trim((tostring(cfg.Folder or cfg.Title or"QustahUI"):gsub("[^%w_%- ]","")))
if folder==""then folder="QustahUI"end
local file=Gate.file(folder)
if spec.Remember~=false and type(isfile)=="function"and type(readfile)=="function"and isfile(file)then
local ok,saved=pcall(readfile,file)
if ok and check(spec,saved)then return true end
end
local genv=(getgenv and getgenv())or _G
if genv.__QustahKeyGate then pcall(genv.__QustahKeyGate)end
local gui=Util.screenGui("QustahUI_Key",70)
UIFont.register(gui,Lib.maid)
local shade=create("Frame",{Name="Shade",Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,Parent=gui})
local panel=create("CanvasGroup",{
Name="KeySystem",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(340,232),
BorderSizePixel=0,GroupTransparency=1,Parent=gui,
})
Theme.bind(panel,"BackgroundColor3","base")
corner(panel,12)
Theme.bind(stroke(panel),"Color","edge")
local scale=create("UIScale",{Scale=0.96,Parent=panel})
local tile=create("Frame",{Name="IconTile",Position=UDim2.fromOffset(20,20),Size=UDim2.fromOffset(36,36),BorderSizePixel=0,Parent=panel})
Theme.bind(tile,"BackgroundColor3","accentDeep")
corner(tile,10)
Theme.bind(stroke(tile,nil,0.6),"Color","accent")
Icons.themed(tile,spec.Icon or"key-round",17,"accent",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
local title=label(panel,tostring(spec.Title or cfg.Title or"Key system"),15,{Name="Title",Position=UDim2.fromOffset(68,19),Size=UDim2.new(1,-110,0,20),Font=Enum.Font.GothamBold})
Theme.bind(title,"TextColor3","heading")
local subtitle=label(panel,tostring(spec.Subtitle or"Enter your key to continue"),10,{Name="Subtitle",Position=UDim2.fromOffset(68,39),Size=UDim2.new(1,-110,0,16)})
Theme.bind(subtitle,"TextColor3","muted")
local close=create("TextButton",{Name="Close",Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,14),Size=UDim2.fromOffset(26,26),Parent=panel})
corner(close,6)
Theme.bind(close,"BackgroundColor3","input")
Icons.themed(close,"x",14,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
local field=create("Frame",{Name="Field",Position=UDim2.fromOffset(20,74),Size=UDim2.new(1,-40,0,34),BorderSizePixel=0,Parent=panel})
Theme.bind(field,"BackgroundColor3","input")
corner(field,8)
local fieldEdge=stroke(field)
Theme.bind(fieldEdge,"Color","buttonEdge")
local box=create("TextBox",{
Name="Box",BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-96,1,0),Text="",
PlaceholderText="Paste your key",TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
ClearTextOnFocus=false,Parent=field,
})
Theme.bind(box,"TextColor3","heading")
Theme.bind(box,"PlaceholderColor3","muted")
local submit=create("TextButton",{
Name="Check",Text="Check",TextSize=10,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),Size=UDim2.fromOffset(76,26),Parent=field,
})
corner(submit,6)
Theme.bind(submit,"BackgroundColor3","accentDeep")
Theme.bind(submit,"TextColor3","accent")
local submitEdge=stroke(submit,nil,0.45)
Theme.bind(submitEdge,"Color","accent")
local status=label(panel,"",10,{Name="Status",Position=UDim2.fromOffset(20,112),Size=UDim2.new(1,-40,0,16)})
Theme.bind(status,"TextColor3","muted")
local note=label(panel,tostring(spec.Note or""),9,{
Name="Note",Position=UDim2.fromOffset(20,132),Size=UDim2.new(1,-40,0,30),TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,TextYAlignment=Enum.TextYAlignment.Top,
})
Theme.bind(note,"TextColor3","muted")
local line=create("Frame",{Position=UDim2.new(0,0,1,-54),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,Parent=panel})
Theme.bind(line,"BackgroundColor3","line")
local getKey=create("TextButton",{
Name="GetKey",Text="",AutoButtonColor=false,BorderSizePixel=0,Position=UDim2.new(0,20,1,-42),Size=UDim2.new(1,-40,0,30),
Visible=spec.Url~=nil,Parent=panel,
})
corner(getKey,7)
Theme.bind(getKey,"BackgroundColor3","input")
Theme.bind(stroke(getKey),"Color","buttonEdge")
local getRow=create("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Parent=getKey})
Util.list(getRow,6,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)
Icons.themed(getRow,"link",12,"text",{LayoutOrder=1})
local getText=label(getRow,"Get key",10,{AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,30),Font=Enum.Font.GothamMedium,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2})
Theme.bind(getText,"TextColor3","text")
if not spec.Url then panel.Size=UDim2.fromOffset(340,178)line.Visible=false end
tween(shade,0.2,{BackgroundTransparency=0.45})
tween(panel,0.2,{GroupTransparency=0})
tween(scale,0.25,{Scale=1},Enum.EasingStyle.Back)
local result,busy=nil,false
local function say(text,role)
status.Text=tostring(text or"")
Theme.bind(status,"TextColor3",role or"muted")
end
local function attempt()
if busy or result~=nil then return end
busy=true
submit.Text="..."
local key=trim(box.Text)
local ok,message=check(spec,key)
busy=false
submit.Text="Check"
if ok then
say(message or"Key accepted","success")
Theme.bind(fieldEdge,"Color","success")
if spec.Remember~=false and type(writefile)=="function"then
pcall(function()if type(isfolder)=="function"and not isfolder(folder)then makefolder(folder)end end)
Util.writeAtomic(file,key)
end
result=true
else
say(message or"Wrong key","danger")
Theme.bind(fieldEdge,"Color","danger")
local x=panel.Position
task.spawn(function()
for _,dx in ipairs({-6,6,-4,4,0})do
panel.Position=x+UDim2.fromOffset(dx,0)
task.wait(0.03)
end
end)
end
end
submit.Activated:Connect(attempt)
box.FocusLost:Connect(function(enter)if enter then attempt()end end)
box:GetPropertyChangedSignal("Text"):Connect(function()
if result==nil and status.Text~=""then say("")Theme.bind(fieldEdge,"Color","buttonEdge")end
end)
getKey.Activated:Connect(function()
local clipboard=setclipboard or toclipboard
local ok=type(clipboard)=="function"and pcall(clipboard,tostring(spec.Url))
say(ok and"Link copied - open it in your browser"or tostring(spec.Url),ok and"accent"or"muted")
end)
close.Activated:Connect(function()result=false end)
local function replaced()if result==nil then result=false end end
genv.__QustahKeyGate=replaced
while result==nil and gui.Parent do task.wait(0.05)end
if result==nil then result=false end
if genv.__QustahKeyGate==replaced then genv.__QustahKeyGate=nil end
tween(shade,0.18,{BackgroundTransparency=1})
tween(panel,0.18,{GroupTransparency=1})
task.delay(0.2,function()gui:Destroy()end)
if result==false then Util.safe(spec.OnCancel)end
return result
end
function Gate.forget(folder)
local file=Gate.file(tostring(folder or"QustahUI"):gsub("[^%w_%- ]",""))
if type(isfile)=="function"and type(delfile)=="function"and isfile(file)then pcall(delfile,file)end
end
return Gate
end
__modules["glow"]=function()
local Util=require("util")
local Theme=require("theme")
local Glow={enabled=true,items={},started=false}
local WHITE=Color3.new(1,1,1)
local function colors(fx)
local base=Theme.get(fx.base)
local shine=fx.shine and Theme.get(fx.shine)or base:Lerp(WHITE,0.6)
return ColorSequence.new({
ColorSequenceKeypoint.new(0,base),ColorSequenceKeypoint.new(0.36,base),ColorSequenceKeypoint.new(0.5,shine),
ColorSequenceKeypoint.new(0.64,base),ColorSequenceKeypoint.new(1,base),
}),base
end
local function apply(fx)
local sequence,base=colors(fx)
fx.gradient.Color=sequence
fx.outline.Color=base
fx.gradient.Enabled,fx.outline.Enabled=Glow.enabled,Glow.enabled
Theme.bind(fx.label,"TextColor3",Glow.enabled and WHITE or fx.base)
end
function Glow.add(label,opts)
opts=opts or{}
local fx={
label=label,base=opts.Base or"text",shine=opts.Shine,period=opts.Period or 3.2,phase=opts.Phase or 0,
gradient=Util.create("UIGradient",{Name="Shine",Offset=Vector2.new(-1.2,0),Parent=label}),
outline=Util.create("UIStroke",{
Name="Glow",ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,LineJoinMode=Enum.LineJoinMode.Round,
Thickness=1,Transparency=opts.GlowTransparency or 0.88,Parent=label,
}),
}
Glow.items[#Glow.items+1]=fx
apply(fx)
return fx
end
function Glow.setEnabled(enabled)
Glow.enabled=enabled~=false
for _,fx in ipairs(Glow.items)do if fx.label.Parent then apply(fx)end end
end
local function visible(object)
while object do
if object:IsA("GuiObject")and not object.Visible then return false end
if object:IsA("LayerCollector")then return object.Enabled end
object=object.Parent
end
return false
end
function Glow.start(maid)
if Glow.started then return end
Glow.started=true
maid:connect(Util.Services.RunService.RenderStepped,function()
if not Glow.enabled then return end
local now=os.clock()
for index=#Glow.items,1,-1 do
local fx=Glow.items[index]
if not fx.label.Parent then
table.remove(Glow.items,index)
elseif visible(fx.label)then
local p=((now/fx.period)+fx.phase)%1
fx.gradient.Offset=Vector2.new(p<0.6 and(-1.2+(p/0.6)*2.4)or 1.2,0)
end
end
end)
maid:give(function()Glow.started=false end)
Theme.onChange(function()for _,fx in ipairs(Glow.items)do if fx.label.Parent then apply(fx)end end end)
end
return Glow
end
__modules["haptics"]=function()
local Util=require("util")
local Haptics={Enabled=Util.isTouch()}
local TYPES
local function types()
if TYPES~=nil then return TYPES end
TYPES=false
pcall(function()
Instance.new("HapticEffect"):Destroy()
TYPES={click=Enum.HapticEffectType.UIHover,notify=Enum.HapticEffectType.UIClick}
end)
return TYPES
end
local pool={}
local last=0
function Haptics.Play(kind)
if not Haptics.Enabled then return end
local list=types()
local hapticType=list and list[kind or"click"]
if not hapticType then return end
local now=os.clock()
if now-last<0.04 then return end
last=now
pcall(function()
local effect=pool[kind]
if not(effect and effect.Parent)then
effect=Instance.new("HapticEffect")
effect.Type=hapticType
effect.Parent=Util.guiParent()
pool[kind]=effect
end
effect:Play()
end)
end
function Haptics.Clear()
for kind,effect in pairs(pool)do pcall(effect.Destroy,effect)pool[kind]=nil end
end
return Haptics
end
__modules["hud"]=function()
local Util=require("util")
local Theme=require("theme")
local Stats=require("stats")
local Glow=require("glow")
local Icons=require("icons")
local Services=Util.Services
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
return function(Window)
function Window:_floating(name,width,height,default)
local panel=create("Frame",{
Name=name,Size=UDim2.fromOffset(width,height),BorderSizePixel=0,BackgroundTransparency=0.04,
Visible=false,ZIndex=70,Parent=self.gui,
})
Theme.bind(panel,"BackgroundColor3","base")
corner(panel,8)
Theme.bind(stroke(panel,nil,0.4),"Color","line")
local handle=create("TextButton",{Name="Handle",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),ZIndex=71,Parent=panel})
local saved=self.memory and self.memory.hud and self.memory.hud[name]
local fraction=saved and Vector2.new(tonumber(saved[1])or default.X,tonumber(saved[2])or default.Y)or default
local function place()
local viewport=Util.viewport()
local room=Vector2.new(math.max(0,viewport.X-panel.AbsoluteSize.X),math.max(0,viewport.Y-panel.AbsoluteSize.Y))
panel.Position=UDim2.fromOffset(math.floor(fraction.X*room.X),math.floor(fraction.Y*room.Y))
end
handle.InputBegan:Connect(function(input)
if not Util.isPress(input)then return end
local start,origin=Util.pointer(input),Vector2.new(panel.Position.X.Offset,panel.Position.Y.Offset)
self:_beginDrag(input,function(point)
local viewport=Util.viewport()
local room=Vector2.new(math.max(1,viewport.X-panel.AbsoluteSize.X),math.max(1,viewport.Y-panel.AbsoluteSize.Y))
local target=origin+(point-start)
fraction=Vector2.new(math.clamp(target.X/room.X,0,1),math.clamp(target.Y/room.Y,0,1))
place()
end,function()
self.memory.hud=self.memory.hud or{}
self.memory.hud[name]={fraction.X,fraction.Y}
self:_saveMemory()
end)
end)
self.maid:connect(panel:GetPropertyChangedSignal("AbsoluteSize"),place)
self._placers=self._placers or{}
table.insert(self._placers,place)
place()
return panel,handle
end
local function chordText(element)
if element.Chord then
local mod,key=element.Chord[1],element.Chord[2]
return(mod and(Util.keyName(mod).." + ")or"")..Util.keyName(key)
end
if element.Type=="Toggle"then return Util.keyName(element.BindKey)end
return Util.keyName(element.Value or element.BindKey)
end
function Window:KeybindList(visible)
visible=visible~=false
if not self._keybindHud then
local panel,handle=self:_floating("Keybinds",210,60,Vector2.new(0.02,0.18))
local caption=label(handle,"Keybinds",10,{Position=UDim2.fromOffset(12,3),Size=UDim2.new(1,-70,1,-3),ZIndex=72})
Theme.bind(caption,"TextColor3","muted")
self.memory.hud=self.memory.hud or{}
local hidden=self.memory.hud.keybindsHidden or{}
local folded=self.memory.hud.keybindsFolded==true
local editing=false
local refresh
local function headerButton(name,x,icon)
local button=create("TextButton",{Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,x,0,5),Size=UDim2.fromOffset(20,20),ZIndex=74,Parent=handle})
local image=Icons.themed(button,icon,12,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=75})
button.MouseEnter:Connect(function()if image then Theme.tweenTo(image,"ImageColor3","heading",0.1)end end)
button.MouseLeave:Connect(function()if image then Theme.tweenTo(image,"ImageColor3",editing and name=="Edit"and"accent"or"muted",0.1)end end)
return button,image
end
local foldButton,foldIcon=headerButton("Fold",-8,folded and"chevron-down"or"chevron-up")
local editButton,editIcon=headerButton("Edit",-30,"eye")
local function remember()
self.memory.hud.keybindsHidden,self.memory.hud.keybindsFolded=hidden,folded
self:_saveMemory()
end
foldButton.Activated:Connect(function()
folded=not folded
if foldIcon then Icons.Apply(foldIcon,folded and"chevron-down"or"chevron-up")end
remember()
refresh()
end)
editButton.Activated:Connect(function()
editing=not editing
if editIcon then Theme.tweenTo(editIcon,"ImageColor3",editing and"accent"or"muted",0.1)end
caption.Text=editing and"Click to hide / show"or"Keybinds"
refresh()
end)
local list=create("Frame",{Name="List",BackgroundTransparency=1,Position=UDim2.fromOffset(8,30),Size=UDim2.new(1,-16,1,-36),ZIndex=71,Parent=panel})
Util.list(list,2)
local rows={}
local function row(index)
if rows[index]then return rows[index]end
local holder=create("TextButton",{Name="Row",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=index,ZIndex=72,Parent=list})
Theme.bind(holder,"BackgroundColor3","hover")
corner(holder,5)
local name=label(holder,"",10,{Position=UDim2.fromOffset(4,0),Size=UDim2.new(1,-80,1,0),ZIndex=73})
local key=label(holder,"",9,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,0),Size=UDim2.new(0,72,1,0),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,ZIndex=73})
Theme.bind(key,"TextColor3","muted")
local r={holder=holder,name=name,key=key}
holder.MouseEnter:Connect(function()holder.BackgroundTransparency=0.4 end)
holder.MouseLeave:Connect(function()holder.BackgroundTransparency=1 end)
holder.Activated:Connect(function()
local entry=r.entry
if not entry then return end
if editing then
if not entry.menu then hidden[entry.title]=not hidden[entry.title]or nil remember()end
elseif entry.element and entry.element._onBind then
local element=entry.element
if element.BindMode=="Hold"and element.Set then
element:Set(not element.Value)
else
self:_safe(entry.title,element._onBind,element)
if element.Mode=="Hold"and element._onRelease then task.delay(0.15,function()self:_safe(entry.title,element._onRelease,element)end)end
end
end
refresh()
end)
rows[index]=r
return r
end
function refresh()
local entries={{title="Menu",key=Util.keyName(self.key),on=true,menu=true}}
for element,bound in pairs(self.binds)do
if bound and element.Row and element.Row.Parent and element.Title and element.Flag~="__ui_menu_key"then
local title=tostring(element.Title)
if editing or not hidden[title]then
local on=element.Type=="Toggle"and element.Value==true or element.Type~="Toggle"
entries[#entries+1]={title=title,key=chordText(element),on=on,element=element,hidden=hidden[title]}
end
end
end
table.sort(entries,function(a,b)
if a.menu~=b.menu then return a.menu==true end
if a.on~=b.on then return a.on end
return a.title<b.title
end)
local shown=folded and 0 or#entries
for index=1,shown do
local entry=entries[index]
local r=row(index)
r.entry=entry
r.holder.Visible=true
r.name.Text,r.key.Text=(entry.hidden and"· "or"")..entry.title,"["..entry.key.."]"
Theme.bind(r.name,"TextColor3",entry.hidden and"muted"or(entry.on and"heading"or"muted"))
r.name.TextTransparency=entry.hidden and 0.4 or 0
end
for index=shown+1,#rows do rows[index].holder.Visible=false rows[index].entry=nil end
list.Visible=not folded
panel.Size=UDim2.fromOffset(210,folded and 30 or(36+shown*22))
end
self._keybindHud={panel=panel,refresh=refresh}
task.spawn(function()
while self.alive do
if panel.Visible then refresh()end
task.wait(0.5)
end
end)
end
self._keybindHud.panel.Visible=visible
if visible then self._keybindHud.refresh()end
end
function Window:SessionBar(visible)
visible=visible~=false
if not self._sessionBar then
Stats.start(self.Lib.maid)
local started=os.clock()
local bar=create("Frame",{
Name="SessionBar",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,20),Size=UDim2.fromOffset(300,30),
BorderSizePixel=0,BackgroundTransparency=0.04,Visible=false,ZIndex=70,Parent=self.gui,
})
Theme.bind(bar,"BackgroundColor3","base")
corner(bar,8)
Theme.bind(stroke(bar,nil,0.4),"Color","line")
local text=label(bar,"",10,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=71})
Theme.bind(text,"TextColor3","text")
local Players=Services.Players
local function refresh()
text.Text=string.format("%d FPS  ·  %d ms  ·  %d/%d  ·  %s",Stats.fps,Stats.ping,#Players:GetPlayers(),Players.MaxPlayers,Util.clock(os.clock()-started))
end
self.maid:give(Stats.listen(function()if bar.Visible then refresh()end end))
self._sessionBar={bar=bar,refresh=refresh}
local function place()
local viewport=Util.viewport()
local barLeft,barRight=viewport.X/2-150,viewport.X/2+150
local crowded=false
for _,name in ipairs({"Watermark","Keybinds","Performance"})do
local panel=self.gui:FindFirstChild(name)
if panel and panel:IsA("GuiObject")and panel.Visible then
local at=Util.screenPos(panel)
local left,right=at.X,at.X+panel.AbsoluteSize.X
if right>barLeft and left<barRight and at.Y<20+30+8 then crowded=true end
end
end
if crowded then
bar.AnchorPoint,bar.Position=Vector2.new(0.5,1),UDim2.new(0.5,0,1,-14)
else
bar.AnchorPoint,bar.Position=Vector2.new(0.5,0),UDim2.new(0.5,0,0,20)
end
end
self._sessionBar.place=place
self._placers=self._placers or{}
table.insert(self._placers,place)
end
self._sessionBar.bar.Visible=visible
if visible then self._sessionBar.refresh()self._sessionBar.place()end
end
function Window:StatsMonitor(mode)
mode=mode==true and"Header"or(mode==false and"Off"or tostring(mode or"Header"))
Stats.start(self.Lib.maid)
if not self._monitor then
local header=label(self.main,"",10,{
Name="HeaderStats",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,12),Size=UDim2.fromOffset(170,20),
TextXAlignment=Enum.TextXAlignment.Center,RichText=true,Visible=false,
})
Theme.bind(header,"TextColor3","muted")
local panel,handle=self:_floating("Performance",190,96,Vector2.new(0.98,0.04))
local caption=label(handle,"Performance",10,{Position=UDim2.fromOffset(12,3),Size=UDim2.new(0.5,0,1,-3),ZIndex=72})
Theme.bind(caption,"TextColor3","muted")
local values=label(handle,"",10,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,3),Size=UDim2.new(0.6,0,1,-3),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamMedium,ZIndex=72})
Theme.bind(values,"TextColor3","text")
local graph=create("Frame",{Name="Graph",BackgroundTransparency=1,Position=UDim2.fromOffset(12,32),Size=UDim2.new(1,-24,1,-42),ZIndex=71,Parent=panel})
local bars={}
for index=1,30 do
local bar=create("Frame",{
AnchorPoint=Vector2.new(0,1),Position=UDim2.new((index-1)/30,0,1,0),Size=UDim2.new(1/30,-1,0,1),
BorderSizePixel=0,BackgroundTransparency=0.25,ZIndex=72,Parent=graph,
})
Theme.bind(bar,"BackgroundColor3","accent")
bars[index]=bar
end
local function refresh()
local text=string.format("FPS %d  ·  PING %d ms",Stats.fps,Stats.ping)
header.Text,values.Text=text,string.format("%d FPS · %d ms",Stats.fps,Stats.ping)
if panel.Visible then
local history=Stats.history.fps
local top=60
for _,value in ipairs(history)do top=math.max(top,value)end
for index=1,30 do
local value=history[#history-30+index]
bars[index].Size=UDim2.new(1/30,-1,value and math.clamp(value/top,0.03,1)or 0,value and 0 or 1)
end
end
end
self.maid:give(Stats.listen(function()if header.Visible or panel.Visible then refresh()end end))
self._monitor={header=header,panel=panel,refresh=refresh}
end
self.monitorMode=mode
self._monitor.header.Visible=mode=="Header"
self._monitor.panel.Visible=mode=="Floating"
self._monitor.refresh()
self:_updateLocation()
end
function Window:Watermark(visible,cfg)
visible=visible~=false
cfg=cfg or{}
if not self._watermark then
Stats.start(self.Lib.maid)
local panel,handle=self:_floating("Watermark",240,28,Vector2.new(0.01,0.01))
local accent=create("Frame",{Name="Bar",Position=UDim2.fromOffset(0,6),Size=UDim2.new(0,2,1,-12),BorderSizePixel=0,ZIndex=72,Parent=panel})
Theme.bind(accent,"BackgroundColor3","accent")
corner(accent,1)
local title=label(handle,self.Title,11,{Name="Title",Position=UDim2.fromOffset(12,0),Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,TextTruncate=Enum.TextTruncate.None,ZIndex=72})
pcall(function()title.FontFace=Font.new(Font.fromEnum(Enum.Font.Gotham).Family,Enum.FontWeight.SemiBold)end)
Theme.bind(title,"TextColor3","accent")
Glow.add(title,{Base="accent",Period=3.6,Phase=0.3,GlowTransparency=0.82})
local info=label(handle,"",10,{Name="Info",Position=UDim2.fromOffset(12,0),Size=UDim2.new(0,200,1,0),TextTruncate=Enum.TextTruncate.None,ZIndex=72})
Theme.bind(info,"TextColor3","text")
local extra=nil
local function refresh()
local parts={}
if self.Version~=""then parts[#parts+1]=self.Version end
if extra and extra~=""then parts[#parts+1]=extra end
parts[#parts+1]=Stats.fps.." FPS"
parts[#parts+1]=Stats.ping.." ms"
parts[#parts+1]=os.date("%H:%M")
info.Text=table.concat(parts,"  |  ")
local titleWidth=Util.textWidth(self.Title,11,Enum.Font.GothamMedium)+4
local infoWidth=Util.textWidth(info.Text,10,Enum.Font.Gotham)+6
info.Position=UDim2.fromOffset(12+titleWidth+10,0)
info.Size=UDim2.new(0,infoWidth,1,0)
panel.Size=UDim2.fromOffset(12+titleWidth+10+infoWidth+12,28)
end
self.maid:give(Stats.listen(function()if panel.Visible then refresh()end end))
self._watermark={panel=panel,refresh=refresh,setExtra=function(text)extra=text end}
end
if cfg.Text~=nil then self._watermark.setExtra(tostring(cfg.Text))end
self._watermark.panel.Visible=visible
if visible then self._watermark.refresh()end
if not self._watermark.watched then
self._watermark.watched=true
self.maid:connect(self._watermark.panel:GetPropertyChangedSignal("Position"),function()if self._sessionBar then self._sessionBar.place()end end)
end
if self._sessionBar then self._sessionBar.place()end
end
end
end
__modules["icons"]=function()
local Icons={
Default="lucide",
Source="https://raw.githubusercontent.com/79650/gwanjkcdsjawbdnjascdas-ui-lib/refs/heads/main/qustah-ui-lib/icons/",
Remote={solar=true,sfsymbols=true,gravity=true,geist=true,craft=true},
Sets={},
_failed={},
}
local Theme=require("theme")
Icons.Sets.lucide=require("icons_lucide")
local ZERO=Vector2.new(0,0)
function Icons.Load(set)
if Icons.Sets[set]then return true end
if not Icons.Remote[set]then return false,"unknown icon set "..tostring(set)end
if Icons._failed[set]then return false,Icons._failed[set]end
local ok,data=pcall(function()
local source=game:HttpGet(Icons.Source..set..".lua")
return loadstring(source)()
end)
if not ok or type(data)~="table"then
Icons._failed[set]=tostring(data)
require("util").log("[qustah-ui-lib] icon set "..set.." could not be loaded: "..tostring(data))
return false,Icons._failed[set]
end
Icons.Sets[set]=data
return true
end
local function asset(value)
if type(value)=="number"then return"rbxassetid://"..value end
return tostring(value)
end
local function lookup(set,name)
local data=Icons.Sets[set]
if not data then return nil end
if type(data.Icons)=="table"and type(data.Spritesheets)=="table"then
local icon=data.Icons[name]
if not icon then return nil end
local parts
for _,part in ipairs(icon.Parts or{})do
parts=parts or{}
parts[#parts+1]=lookup(set,part)
end
return{
Image=asset(data.Spritesheets[tostring(icon.Image)]or icon.Image),
RectSize=icon.ImageRectSize or ZERO,RectOffset=icon.ImageRectPosition or ZERO,Parts=parts,
}
end
local value=data[name]
if value==nil then return nil end
return{Image=asset(value),RectSize=ZERO,RectOffset=ZERO}
end
function Icons.Get(name)
if name==nil or name==""then return nil end
if type(name)=="number"or(type(name)=="string"and name:match("^%d+$"))then
return{Image="rbxassetid://"..tostring(name),RectSize=ZERO,RectOffset=ZERO}
end
name=tostring(name)
if name:match("^https?://")and not name:find("roblox%.com")then
return{Image=Icons._urls[name]or"",RectSize=ZERO,RectOffset=ZERO,Url=name}
end
if name:match("^rbxasset")or name:match("^https?://")then
return{Image=name,RectSize=ZERO,RectOffset=ZERO}
end
local set,icon=name:match("^([%w_%-]+):(.+)$")
if not set then set,icon=Icons.Default,name end
set=set:lower()
if not Icons.Sets[set]then Icons.Load(set)end
return lookup(set,icon)or(set~="lucide"and not name:find(":")and lookup("lucide",icon))or nil
end
Icons._urls={}
Icons.Folder="QustahUI/assets"
local function fetch(url,done)
if Icons._urls[url]then return done(Icons._urls[url])end
task.spawn(function()
local ok,asset=pcall(function()
local name=url:match("([^/?#]+)[?#]?[^/]*$")or"image"
name=name:gsub("%.[^%.]+$",""):gsub("[^%w%-_]","_"):sub(1,40)
local file=Icons.Folder.."/"..name.."-"..#url..".png"
if not(isfile and isfile(file))then
local request=(syn and syn.request)or http_request or request
local body
if request then body=request({Url=url,Method="GET"}).Body else body=game:HttpGet(url)end
assert(type(body)=="string"and#body>0,"empty response")
if makefolder and isfolder then
if not isfolder("QustahUI")then makefolder("QustahUI")end
if not isfolder(Icons.Folder)then makefolder(Icons.Folder)end
end
writefile(file,body)
end
return(getcustomasset or getsynasset)(file)
end)
if ok and asset then
Icons._urls[url]=asset
done(asset)
else
require("util").log("[qustah-ui-lib] image "..url.." could not be loaded: "..tostring(asset))
end
end)
end
function Icons.Apply(image,name)
for _,child in ipairs(image:GetChildren())do if child.Name=="IconPart"then child:Destroy()end end
local icon=Icons.Get(name)
if not icon then return false end
if icon.Url then
image.ImageColor3=Color3.new(1,1,1)
image.ImageRectSize,image.ImageRectOffset=ZERO,ZERO
fetch(icon.Url,function(asset)image.Image=asset end)
return true
end
image.Image=icon.Image
image.ImageRectSize=icon.RectSize
image.ImageRectOffset=icon.RectOffset
for _,part in ipairs(icon.Parts or{})do
local child=Instance.new("ImageLabel")
child.Name="IconPart"
child.BackgroundTransparency=1
child.Size=UDim2.fromScale(1,1)
child.Image,child.ImageRectSize,child.ImageRectOffset=part.Image,part.RectSize,part.RectOffset
child.ImageTransparency=0.5
child.ZIndex=image.ZIndex
child.Parent=image
child.ImageColor3=image.ImageColor3
image:GetPropertyChangedSignal("ImageColor3"):Connect(function()child.ImageColor3=image.ImageColor3 end)
end
return true
end
function Icons.Image(name,props)
props=props or{}
local image=Instance.new("ImageLabel")
image.Name=props.Name or"Icon"
image.BackgroundTransparency=1
image.ScaleType=Enum.ScaleType.Fit
image.Size=props.Size or UDim2.fromOffset(16,16)
if typeof(props.Color)=="Color3"then image.ImageColor3=props.Color end
Icons.Apply(image,name)
image.Parent=props.Parent
return image
end
function Icons.themed(parent,name,size,role,props)
if not Icons.Get(name)then return nil end
local image=Icons.Image(name,{Size=UDim2.fromOffset(size,size),Name=props and props.Name or"Icon"})
for key,value in pairs(props or{})do if key~="Name"then image[key]=value end end
if not Icons.Get(name).Url then Theme.bind(image,"ImageColor3",role or"text")end
image.Parent=parent
return image
end
function Icons.SetDefault(set)
set=tostring(set):lower()
if Icons.Sets[set]or Icons.Load(set)then Icons.Default=set return true end
return false
end
function Icons.Add(set,data)
set=tostring(set):lower()
Icons.Sets[set]=Icons.Sets[set]or{}
for name,value in pairs(data)do Icons.Sets[set][name]=value end
end
function Icons.List(set)
set=tostring(set or Icons.Default):lower()
if not Icons.Sets[set]then Icons.Load(set)end
local data=Icons.Sets[set]or{}
local names={}
for name in pairs(type(data.Icons)=="table"and data.Icons or data)do
if type(name)=="string"then names[#names+1]=name end
end
table.sort(names)
return names
end
return Icons
end
__modules["icons_lucide"]=function()
return{
["a-arrow-down"]=92867583610071,["a-arrow-up"]=132318504999733,["a-large-small"]=111491496660216,["accessibility"]=114029945302017,["activity"]=94212016861936,["air-vent"]=81517226012329,
["airplay"]=115020759309179,["alarm-clock-check"]=76437352099157,["alarm-clock-minus"]=77364179863205,["alarm-clock-off"]=97904885874823,["alarm-clock-plus"]=80468822979214,["alarm-clock"]=126259032907535,
["alarm-smoke"]=96965448419685,["album"]=127358331163602,["align-center-horizontal"]=81570549209434,["align-center-vertical"]=118470463752466,["align-end-horizontal"]=139502909745427,["align-end-vertical"]=96528869059554,
["align-horizontal-distribute-center"]=97220086126656,["align-horizontal-distribute-end"]=106128590702022,["align-horizontal-distribute-start"]=76074660002997,["align-horizontal-justify-center"]=75732302772427,["align-horizontal-justify-end"]=129167626402283,["align-horizontal-justify-start"]=130161830325281,
["align-horizontal-space-around"]=91646106782950,["align-horizontal-space-between"]=103886093046990,["align-start-horizontal"]=125674804697729,["align-start-vertical"]=105020230154823,["align-vertical-distribute-center"]=93791183635525,["align-vertical-distribute-end"]=139354223511433,
["align-vertical-distribute-start"]=74961997822126,["align-vertical-justify-center"]=134754696166569,["align-vertical-justify-end"]=92569381441969,["align-vertical-justify-start"]=99692844572718,["align-vertical-space-around"]=96206012459190,["align-vertical-space-between"]=124998077349706,
["ambulance"]=78599995190651,["ampersand"]=75272915739209,["ampersands"]=126947193455996,["amphora"]=137370389604364,["anchor"]=92181172123618,["angry"]=74237056000103,
["annoyed"]=80064369052011,["antenna"]=99628923540956,["anvil"]=100203029845919,["aperture"]=83396154449972,["app-window-mac"]=79587216113811,["app-window"]=93142176757189,
["apple"]=104349242902442,["archive-restore"]=78956681942188,["archive-x"]=75830115088395,["archive"]=122180020814574,["armchair"]=105384358373973,["arrow-big-down-dash"]=137987229582002,
["arrow-big-down"]=81081164158885,["arrow-big-left-dash"]=97827621354677,["arrow-big-left"]=85973092492641,["arrow-big-right-dash"]=117825834972403,["arrow-big-right"]=82960676755590,["arrow-big-up-dash"]=99260194327483,
["arrow-big-up"]=93136954756149,["arrow-down-0-1"]=120961896217875,["arrow-down-1-0"]=93474255891850,["arrow-down-a-z"]=99554596207900,["arrow-down-from-line"]=132045845807798,["arrow-down-left"]=102899325237364,
["arrow-down-narrow-wide"]=129105261655061,["arrow-down-right"]=123109928624974,["arrow-down-to-dot"]=101675355931221,["arrow-down-to-line"]=87050478931254,["arrow-down-up"]=85780258549577,["arrow-down-wide-narrow"]=88461733425991,
["arrow-down-z-a"]=76115279362232,["arrow-down"]=98764963621439,["arrow-left-from-line"]=87857914437603,["arrow-left-right"]=131324733048447,["arrow-left-to-line"]=118645136026970,["arrow-left"]=102531941843733,
["arrow-right-from-line"]=74073639809355,["arrow-right-left"]=77015754304300,["arrow-right-to-line"]=78632510329852,["arrow-right"]=113692007244654,["arrow-up-0-1"]=105257823943016,["arrow-up-1-0"]=134175521693798,
["arrow-up-a-z"]=77763416595160,["arrow-up-down"]=81019887641527,["arrow-up-from-dot"]=124408496673275,["arrow-up-from-line"]=95777664626453,["arrow-up-left"]=123490598231261,["arrow-up-narrow-wide"]=73006024672636,
["arrow-up-right"]=129280608535523,["arrow-up-to-line"]=108818207813537,["arrow-up-wide-narrow"]=87437426951568,["arrow-up-z-a"]=107546173611884,["arrow-up"]=89282378235317,["arrows-up-from-line"]=133710016938621,
["asterisk"]=88552752106723,["at-sign"]=79059152889146,["atom"]=73167696981648,["audio-lines"]=70930641819242,["audio-waveform"]=86462036665209,["award"]=132740088158419,
["axe"]=132405197863294,["axis-3d"]=122438676546804,["baby"]=93472926933440,["backpack"]=140420225386018,["badge-alert"]=101829200081951,["badge-cent"]=133345018873154,
["badge-check"]=76078495178149,["badge-dollar-sign"]=127139803581141,["badge-euro"]=120016477674659,["badge-indian-rupee"]=75659682309981,["badge-info"]=131995373201472,["badge-japanese-yen"]=99081574588615,
["badge-minus"]=140321561183881,["badge-percent"]=121359224294885,["badge-plus"]=100325578561866,["badge-pound-sterling"]=119688217279444,["badge-question-mark"]=121464963737502,["badge-russian-ruble"]=108839463659864,
["badge-swiss-franc"]=91447608372740,["badge-turkish-lira"]=137839965873529,["badge-x"]=122931434733842,["badge"]=116620312917084,["baggage-claim"]=86922213051957,["ban"]=90767043015246,
["banana"]=140713420056179,["bandage"]=129660129590770,["banknote-arrow-down"]=139366449345199,["banknote-arrow-up"]=133758343082529,["banknote-x"]=95348701438065,["banknote"]=104840231536668,
["barcode"]=118473018143689,["barrel"]=130647115622774,["baseline"]=124677132511270,["bath"]=76031400297942,["battery-charging"]=80139357470047,["battery-full"]=70906718268972,
["battery-low"]=139659256984314,["battery-medium"]=105934079398915,["battery-plus"]=91931341486966,["battery-warning"]=115230083817257,["battery"]=70765800346189,["beaker"]=80902539995520,
["bean-off"]=98164436608714,["bean"]=89491967076869,["bed-double"]=73820193212911,["bed-single"]=113423940880634,["bed"]=97726529032925,["beef"]=105850162318915,
["beer-off"]=120333134736361,["beer"]=116404978807744,["bell-dot"]=93161277118810,["bell-electric"]=100277767266983,["bell-minus"]=126334890449727,["bell-off"]=78560046118930,
["bell-plus"]=77014333795836,["bell-ring"]=94612128913941,["bell"]=97392696311902,["between-horizontal-end"]=81602774794322,["between-horizontal-start"]=76112384929846,["between-vertical-end"]=72817612571631,
["between-vertical-start"]=85278312190301,["biceps-flexed"]=82004462003936,["bike"]=102930322246035,["binary"]=91751953950088,["binoculars"]=101460003267896,["biohazard"]=95956532900432,
["bird"]=132284145117371,["birdhouse"]=83999157401433,["bitcoin"]=95459240442938,["blend"]=111679612185257,["blinds"]=71164165283925,["blocks"]=72212693357737,
["bluetooth-connected"]=96315134002985,["bluetooth-off"]=80600044218117,["bluetooth-searching"]=100673019606426,["bluetooth"]=90506573139443,["bold"]=116141470019166,["bolt"]=102881251417484,
["bomb"]=139223800924636,["bone"]=111242153474115,["book-a"]=104067275658465,["book-alert"]=124159928044853,["book-audio"]=109208148317037,["book-check"]=115999656081696,
["book-copy"]=108543407492005,["book-dashed"]=127430784795958,["book-down"]=101011730128222,["book-headphones"]=108670200799574,["book-heart"]=112788845135284,["book-image"]=80808285757226,
["book-key"]=116024426170705,["book-lock"]=118765061220571,["book-marked"]=73211024251780,["book-minus"]=112724962046282,["book-open-check"]=130848362492667,["book-open-text"]=100629528672195,
["book-open"]=129845326810392,["book-plus"]=140267785051233,["book-text"]=94011772484232,["book-type"]=97817304725443,["book-up-2"]=130161620853665,["book-up"]=98640174079190,
["book-user"]=128489189240523,["book-x"]=118754548186537,["book"]=125383279695672,["bookmark-check"]=93940443347986,["bookmark-minus"]=96807096039910,["bookmark-plus"]=121469724491615,
["bookmark-x"]=112272342584706,["bookmark"]=121093149326239,["boom-box"]=99901322535868,["bot-message-square"]=96145330292478,["bot-off"]=140417690560013,["bot"]=80451686744860,
["bottle-wine"]=131675403196921,["bow-arrow"]=124089655150375,["box"]=101768155599700,["boxes"]=136372617578355,["braces"]=117761094704041,["brackets"]=74368995728099,
["brain-circuit"]=70547962410202,["brain-cog"]=132039205501538,["brain"]=92424107303177,["brick-wall-fire"]=92980588705520,["brick-wall-shield"]=75954432775071,["brick-wall"]=112878522258821,
["briefcase-business"]=129135125207283,["briefcase-conveyor-belt"]=108665725653714,["briefcase-medical"]=119917756334087,["briefcase"]=96754188164225,["bring-to-front"]=132975903553748,["brush-cleaning"]=71728977448805,
["brush"]=127035535799640,["bubbles"]=106183424168227,["bug-off"]=88020025049245,["bug-play"]=80107955888092,["bug"]=83626408925438,["building-2"]=77873775611951,
["building"]=110616258983082,["bus-front"]=89863432456045,["bus"]=133798469717463,["cable-car"]=128643682205596,["cable"]=128449944504901,["cake-slice"]=136769828413242,
["cake"]=103131590503275,["calculator"]=74915716529646,["calendar-1"]=98458364171044,["calendar-arrow-down"]=108415736543437,["calendar-arrow-up"]=70574654109118,["calendar-check-2"]=120231170248276,
["calendar-check"]=71551019465748,["calendar-clock"]=119132152594595,["calendar-cog"]=122402172360287,["calendar-days"]=99072017568595,["calendar-fold"]=117368871270394,["calendar-heart"]=88839008103676,
["calendar-minus-2"]=98846170279891,["calendar-minus"]=137354318924383,["calendar-off"]=109726151749217,["calendar-plus-2"]=112264562093883,["calendar-plus"]=125266115249843,["calendar-range"]=103641849247576,
["calendar-search"]=92010083223634,["calendar-sync"]=78082218499697,["calendar-x-2"]=107518051061147,["calendar-x"]=106703374806500,["calendar"]=114792700814035,["camera-off"]=81057636835256,
["camera"]=79950339943067,["candy-cane"]=71689468772492,["candy-off"]=110232752314832,["candy"]=107812129154678,["cannabis"]=98792006538601,["captions-off"]=105223545364193,
["captions"]=104960225031445,["car-front"]=87380942739063,["car-taxi-front"]=122455403384057,["car"]=121065933462582,["caravan"]=120070979471783,["card-sim"]=134490550095771,
["carrot"]=119118221444304,["case-lower"]=129303130603241,["case-sensitive"]=125410273293056,["case-upper"]=111633433531325,["cassette-tape"]=137065788934157,["cast"]=98202245922071,
["castle"]=119275077187784,["cat"]=124252153404931,["cctv"]=99979894766624,["chart-area"]=123446436762366,["chart-bar-big"]=72336824986044,["chart-bar-decreasing"]=107217459044963,
["chart-bar-increasing"]=88268905998571,["chart-bar-stacked"]=98478751113024,["chart-bar"]=105389816384108,["chart-candlestick"]=125676898615697,["chart-column-big"]=98598733210787,["chart-column-decreasing"]=73586137373563,
["chart-column-increasing"]=120421615068601,["chart-column-stacked"]=86031449675105,["chart-column"]=97915995538580,["chart-gantt"]=88811660555940,["chart-line"]=101833156055618,["chart-network"]=104027882693561,
["chart-no-axes-column-decreasing"]=123371717192542,["chart-no-axes-column-increasing"]=140383830943049,["chart-no-axes-column"]=94078751170351,["chart-no-axes-combined"]=121424233161912,["chart-no-axes-gantt"]=131936541106368,["chart-pie"]=113412261630136,
["chart-scatter"]=108217585014571,["chart-spline"]=90307460742494,["check-check"]=95183312173858,["check-line"]=115122343485290,["check"]=93898873302694,["chef-hat"]=121744015002573,
["cherry"]=139519182403183,["chess-bishop"]=121701705580238,["chess-king"]=90885687223462,["chess-knight"]=96467707042169,["chess-pawn"]=111318574652751,["chess-queen"]=98304702099749,
["chess-rook"]=76223925830262,["chevron-down"]=134243273101015,["chevron-first"]=105243363790238,["chevron-last"]=89268452603731,["chevron-left"]=73780377692148,["chevron-right"]=92473583511724,
["chevron-up"]=122444883127455,["chevrons-down-up"]=139404716013205,["chevrons-down"]=100524612205956,["chevrons-left-right-ellipsis"]=125035817741526,["chevrons-left-right"]=87910685945204,["chevrons-left"]=82617201744347,
["chevrons-right-left"]=87149546686569,["chevrons-right"]=139121276490483,["chevrons-up-down"]=131833120209646,["chevrons-up"]=100467452364672,["chromium"]=128165143739006,["church"]=113714744350666,
["cigarette-off"]=77797883078452,["circle-alert"]=83898160590116,["circle-arrow-down"]=95901860261344,["circle-arrow-left"]=102148876968988,["circle-arrow-out-down-left"]=140598097856694,["circle-arrow-out-down-right"]=119952801379305,
["circle-arrow-out-up-left"]=132858212688303,["circle-arrow-out-up-right"]=81783743753173,["circle-arrow-right"]=70786767999559,["circle-arrow-up"]=84395128546494,["circle-check-big"]=93202927221730,["circle-check"]=85262178816537,
["circle-chevron-down"]=137069490345718,["circle-chevron-left"]=130250009740827,["circle-chevron-right"]=125943696958495,["circle-chevron-up"]=111223574026321,["circle-dashed"]=126799443883746,["circle-divide"]=106398997754208,
["circle-dollar-sign"]=91106238890387,["circle-dot-dashed"]=111451232827180,["circle-dot"]=82947033619201,["circle-ellipsis"]=91687150884779,["circle-equal"]=95133963751438,["circle-fading-arrow-up"]=104648212910336,
["circle-fading-plus"]=91847890443490,["circle-gauge"]=108157549473765,["circle-minus"]=133556159576809,["circle-off"]=97923456918886,["circle-parking-off"]=128369410981252,["circle-parking"]=124034962915196,
["circle-pause"]=139337739700879,["circle-percent"]=133311912860256,["circle-play"]=120408917249739,["circle-plus"]=113157136350384,["circle-pound-sterling"]=105476153083828,["circle-power"]=140676030155098,
["circle-question-mark"]=97516698664325,["circle-slash-2"]=136766902186549,["circle-slash"]=125206439913049,["circle-small"]=73685402843600,["circle-star"]=120318414957104,["circle-stop"]=87400503942659,
["circle-user-round"]=95489465399880,["circle-user"]=136220511671311,["circle-x"]=76821953846248,["circle"]=130359823580534,["circuit-board"]=107695264369312,["citrus"]=139018222976433,
["clapperboard"]=132660667070200,["clipboard-check"]=92649798577170,["clipboard-clock"]=123957515687745,["clipboard-copy"]=125851897718493,["clipboard-list"]=96460215958908,["clipboard-minus"]=107968008485671,
["clipboard-paste"]=74382068849983,["clipboard-pen-line"]=77711589791615,["clipboard-pen"]=75290966822953,["clipboard-plus"]=134285318675662,["clipboard-type"]=89949374318028,["clipboard-x"]=102222456890103,
["clipboard"]=89601995828423,["clock-1"]=129363225422045,["clock-10"]=104332695855541,["clock-11"]=119023205186105,["clock-12"]=117789618723068,["clock-2"]=134710777209413,
["clock-3"]=136385631189327,["clock-4"]=121808839832144,["clock-5"]=85082019959457,["clock-6"]=71009733505593,["clock-7"]=103111188546225,["clock-8"]=110059272125337,
["clock-9"]=77610027126437,["clock-alert"]=97157344465162,["clock-arrow-down"]=92349314416042,["clock-arrow-up"]=111484286332629,["clock-check"]=85231630218857,["clock-fading"]=93205297285245,
["clock-plus"]=93367709263150,["clock"]=121808839832144,["closed-caption"]=99832644030788,["cloud-alert"]=91967273658626,["cloud-check"]=97318598202432,["cloud-cog"]=96497764065749,
["cloud-download"]=121435581993566,["cloud-drizzle"]=139525315752605,["cloud-fog"]=76650233148776,["cloud-hail"]=72320462748242,["cloud-lightning"]=133517088924849,["cloud-moon-rain"]=127667837827018,
["cloud-moon"]=71938114737914,["cloud-off"]=131907154501444,["cloud-rain-wind"]=107414583736721,["cloud-rain"]=105547081967408,["cloud-snow"]=72307126270226,["cloud-sun-rain"]=99041604425705,
["cloud-sun"]=86114208148727,["cloud-upload"]=93307473217005,["cloud"]=121226497050352,["cloudy"]=105360479023346,["clover"]=74925550436750,["club"]=108490365816628,
["code-xml"]=130150477351734,["code"]=107380207681249,["codepen"]=135643965971885,["codesandbox"]=106911852964823,["coffee"]=106864403231093,["cog"]=116544501716299,
["coins"]=116510979641930,["columns-2"]=113004100221850,["columns-3-cog"]=121589691981064,["columns-3"]=115223357399375,["columns-4"]=130807991968419,["combine"]=79908476334048,
["command"]=93648221906330,["compass"]=115123411028382,["component"]=110027788875080,["computer"]=77480056459407,["concierge-bell"]=140384259310436,["cone"]=97759550688437,
["construction"]=106539489968173,["contact-round"]=71907624112229,["contact"]=75868297719012,["container"]=91507237573499,["contrast"]=112796643981497,["cookie"]=73159504540002,
["cooking-pot"]=94959783129799,["copy-check"]=91177247988892,["copy-minus"]=109524509933035,["copy-plus"]=113618379616952,["copy-slash"]=93805787810390,["copy-x"]=106557557978061,
["copy"]=78979572434545,["copyleft"]=78559055698593,["copyright"]=129433635747111,["corner-down-left"]=90473561177832,["corner-down-right"]=86512767702085,["corner-left-down"]=139876989150630,
["corner-left-up"]=126228268096099,["corner-right-down"]=89237035551302,["corner-right-up"]=112851237026705,["corner-up-left"]=84669279763024,["corner-up-right"]=115099889693145,["cpu"]=77549309870247,
["creative-commons"]=90408210735312,["credit-card"]=99163352872346,["croissant"]=130710485559420,["crop"]=116344601101413,["cross"]=101833377863588,["crosshair"]=134242818164054,
["crown"]=127843403295538,["cuboid"]=75618807946111,["cup-soda"]=121098640829562,["currency"]=90551250119972,["cylinder"]=90569677179169,["dam"]=76874486231393,
["database-backup"]=103403210984699,["database-zap"]=131199921258418,["database"]=126791525623846,["decimals-arrow-left"]=120198500638749,["decimals-arrow-right"]=118263047146797,["delete"]=126279426372342,
["dessert"]=71508133278830,["diameter"]=97429051503783,["diamond-minus"]=128989071438290,["diamond-percent"]=107717860105959,["diamond-plus"]=134701163723675,["diamond"]=105846996304890,
["dice-1"]=112650149591038,["dice-2"]=112278274566793,["dice-3"]=118526270626312,["dice-4"]=113365650364004,["dice-5"]=72768312430593,["dice-6"]=85376239182543,
["dices"]=81268120302865,["diff"]=135052708609715,["disc-2"]=91419420404185,["disc-3"]=135470554736048,["disc-album"]=74693460404344,["disc"]=101908120120777,
["divide"]=136678191878278,["dna-off"]=89612426361540,["dna"]=74007982981741,["dock"]=121997427160252,["dog"]=71920105558570,["dollar-sign"]=127320961224019,
["donut"]=72204922742657,["door-closed-locked"]=74027613267551,["door-closed"]=136249099949073,["door-open"]=91306356501736,["dot"]=137321056643916,["download"]=134814648082393,
["drafting-compass"]=99701976182841,["drama"]=110297795801577,["dribbble"]=80231809663849,["drill"]=108644821412796,["drone"]=117299095794783,["droplet-off"]=119365002225172,
["droplet"]=100597455015098,["droplets"]=140111846025180,["drum"]=136979060344890,["drumstick"]=104662462521709,["dumbbell"]=80277236776212,["ear-off"]=87421916192807,
["ear"]=121894949934209,["earth-lock"]=88814147073745,["earth"]=76231597751076,["eclipse"]=114829622118222,["egg-fried"]=90622538210545,["egg-off"]=92288321309285,
["egg"]=117851493400222,["ellipsis-vertical"]=117978708573781,["ellipsis"]=140019550645825,["equal-approximately"]=105382689698323,["equal-not"]=76864449458032,["equal"]=123467780715624,
["eraser"]=133957773112410,["ethernet-port"]=75391715149314,["euro"]=72229646524456,["ev-charger"]=97906158859623,["expand"]=137492887754537,["external-link"]=129331830773832,
["eye-closed"]=111063268625789,["eye-off"]=135928786788378,["eye"]=100033680381365,["facebook"]=72098528632192,["factory"]=102170024318039,["fan"]=78391400440696,
["fast-forward"]=121615540167909,["feather"]=91872927606406,["fence"]=123451565578029,["ferris-wheel"]=79729205796176,["figma"]=134182122852301,["file-archive"]=77018106869967,
["file-axis-3d"]=133912328009885,["file-badge"]=74564895394477,["file-box"]=119264004071690,["file-braces-corner"]=77253337986109,["file-braces"]=95314128621234,["file-chart-column-increasing"]=134449481172067,
["file-chart-column"]=82048481252560,["file-chart-line"]=71954360551345,["file-chart-pie"]=81072193564497,["file-check-corner"]=76295552859171,["file-check"]=82604001452455,["file-clock"]=102325208830990,
["file-code-corner"]=78293841184371,["file-code"]=130978036895504,["file-cog"]=101385347151368,["file-diff"]=96147216772241,["file-digit"]=89220220354580,["file-down"]=120650154178290,
["file-exclamation-point"]=102821865889635,["file-headphone"]=100533735901986,["file-heart"]=132214916401696,["file-image"]=123334057511782,["file-input"]=124728604166044,["file-key"]=118790255921100,
["file-lock"]=72170228691242,["file-minus-corner"]=119263271735124,["file-minus"]=111014798459222,["file-music"]=134948051536671,["file-output"]=92146832572911,["file-pen-line"]=104622936345006,
["file-pen"]=79556179730240,["file-play"]=89006821567838,["file-plus-corner"]=76544604043974,["file-plus"]=78881710800060,["file-question-mark"]=127617422859576,["file-scan"]=129480105228213,
["file-search-corner"]=90974165234008,["file-search"]=97780235974933,["file-signal"]=122070252538165,["file-sliders"]=85787771732439,["file-spreadsheet"]=134501869359270,["file-stack"]=138929929862605,
["file-symlink"]=91865722036510,["file-terminal"]=116757454755476,["file-text"]=90496405707281,["file-type-corner"]=124902230275209,["file-type"]=115272552799361,["file-up"]=131173039312748,
["file-user"]=99552018455009,["file-video-camera"]=81719056173960,["file-volume"]=111264764438958,["file-x-corner"]=87554136773609,["file-x"]=107333775515154,["file"]=74748492079329,
["files"]=102806336233202,["film"]=120978945609706,["fingerprint"]=112173305232811,["fire-extinguisher"]=111643493006960,["fish-off"]=89756724887508,["fish-symbol"]=118475177681618,
["fish"]=124360663785796,["flag-off"]=112944528856799,["flag-triangle-left"]=88045221285272,["flag-triangle-right"]=108292480304566,["flag"]=78183383236196,["flame-kindling"]=139728976917928,
["flame"]=98218034436456,["flashlight-off"]=79780362871740,["flashlight"]=100286985600444,["flask-conical-off"]=112597970025298,["flask-conical"]=128406680901165,["flask-round"]=127508287324940,
["flip-horizontal-2"]=103726993598186,["flip-horizontal"]=122937530107837,["flip-vertical-2"]=103836358956328,["flip-vertical"]=108003917346888,["flower-2"]=72934574245145,["flower"]=86129438272762,
["focus"]=87493973153317,["fold-horizontal"]=92835712442240,["fold-vertical"]=108873727253656,["folder-archive"]=97312009460206,["folder-check"]=128492920904557,["folder-clock"]=111964836738545,
["folder-closed"]=118286209350843,["folder-code"]=70624096349370,["folder-cog"]=85299519462846,["folder-dot"]=138687772725278,["folder-down"]=118044108459225,["folder-git-2"]=101394054141166,
["folder-git"]=121885778095158,["folder-heart"]=79104747211105,["folder-input"]=90699920697871,["folder-kanban"]=78313285104072,["folder-key"]=85270407596791,["folder-lock"]=119201572260567,
["folder-minus"]=85648718999010,["folder-open-dot"]=74741494767354,["folder-open"]=76018996254888,["folder-output"]=101532447937612,["folder-pen"]=112770491173911,["folder-plus"]=91865663406119,
["folder-root"]=103333751154693,["folder-search-2"]=71276453442655,["folder-search"]=110568075123861,["folder-symlink"]=127485747227189,["folder-sync"]=91544602659796,["folder-tree"]=85577554337861,
["folder-up"]=72008269765857,["folder-x"]=91699618247635,["folder"]=80846616596607,["folders"]=110351216219061,["footprints"]=139192589041315,["forklift"]=72030930983101,
["forward"]=97545944739523,["frame"]=109080612832751,["framer"]=108384807262391,["frown"]=124407301067982,["fuel"]=106447647274511,["fullscreen"]=77793665526178,
["funnel-plus"]=100780233821928,["funnel-x"]=70984385812555,["funnel"]=108829540827529,["gallery-horizontal-end"]=74672430161161,["gallery-horizontal"]=80004001442122,["gallery-thumbnails"]=136219289862706,
["gallery-vertical-end"]=106461402088317,["gallery-vertical"]=119299431466725,["gamepad-2"]=92483947987410,["gamepad-directional"]=84342305212226,["gamepad"]=121607283959010,["gauge"]=110273524101447,
["gavel"]=78952298198456,["gem"]=112904952151156,["georgian-lari"]=98084432591687,["ghost"]=113822048130017,["gift"]=109855212076373,["git-branch-minus"]=97385010649411,
["git-branch-plus"]=125944221134316,["git-branch"]=90490195516649,["git-commit-horizontal"]=133646041800147,["git-commit-vertical"]=122098032990350,["git-compare-arrows"]=84874426520216,["git-compare"]=91945124438792,
["git-fork"]=89954992404765,["git-graph"]=86166832019304,["git-merge"]=131833355158059,["git-pull-request-arrow"]=94507974577439,["git-pull-request-closed"]=78070600389091,["git-pull-request-create-arrow"]=127422677061091,
["git-pull-request-create"]=105929577383926,["git-pull-request-draft"]=76173459869943,["git-pull-request"]=138463010991471,["github"]=120349554354380,["gitlab"]=114054627192933,["glass-water"]=115526102400988,
["glasses"]=87936407455373,["globe-lock"]=134065526704402,["globe"]=114238209622913,["goal"]=120517954878160,["gpu"]=95577823614219,["graduation-cap"]=93771896340220,
["grape"]=134760640415561,["grid-2x2-check"]=138468840220821,["grid-2x2-plus"]=91811610580247,["grid-2x2-x"]=72407303981388,["grid-2x2"]=99050491897640,["grid-3x2"]=95528684210010,
["grid-3x3"]=70419024781206,["grip-horizontal"]=136255899715930,["grip-vertical"]=137183678565296,["grip"]=109058783556768,["group"]=107643418926671,["guitar"]=75915531867926,
["ham"]=74465607934635,["hamburger"]=93086916815495,["hammer"]=83545120140895,["hand-coins"]=126990543175462,["hand-fist"]=83341608917591,["hand-grab"]=88867162163985,
["hand-heart"]=117507367668412,["hand-helping"]=89897738419446,["hand-metal"]=113619498548713,["hand-platter"]=88594727743168,["hand"]=130703864968637,["handbag"]=135675846264061,
["handshake"]=78442115255814,["hard-drive-download"]=73913801230614,["hard-drive-upload"]=85762133615118,["hard-drive"]=88183305858463,["hard-hat"]=128050846767382,["hash"]=82890331678520,
["hat-glasses"]=101165538224815,["haze"]=108857561768901,["hdmi-port"]=103693661037020,["heading-1"]=118129315662110,["heading-2"]=110209069670094,["heading-3"]=90267885237062,
["heading-4"]=129625620307602,["heading-5"]=120386663181267,["heading-6"]=90959079775093,["heading"]=129254312067735,["headphone-off"]=85038251615641,["headphones"]=118833729589183,
["headset"]=129269236787694,["heart-crack"]=110987638564119,["heart-handshake"]=111483078692002,["heart-minus"]=96827380163326,["heart-off"]=89748414415617,["heart-plus"]=94877796283249,
["heart-pulse"]=129352925579546,["heart"]=116559368303288,["heater"]=140478466880916,["helicopter"]=111557171735930,["hexagon"]=127592089339199,["highlighter"]=77411555641113,
["history"]=123980022019922,["hop-off"]=103386036934034,["hop"]=82778923997672,["hospital"]=105868763850707,["hotel"]=132283390859718,["hourglass"]=86160434939203,
["house-heart"]=136054771868597,["house-plug"]=71438263712075,["house-plus"]=118495165208309,["house-wifi"]=126495519725698,["house"]=98755624629571,["ice-cream-bowl"]=124867218454386,
["ice-cream-cone"]=90751397288639,["id-card-lanyard"]=90761480469224,["id-card"]=75354294622640,["image-down"]=78972295741235,["image-minus"]=101066016918565,["image-off"]=81934811700938,
["image-play"]=129501806784210,["image-plus"]=70391970623917,["image-up"]=126610009605241,["image-upscale"]=106963545024679,["images"]=79350649395557,["import"]=116545008906029,
["inbox"]=112591360302868,["indian-rupee"]=113038778381805,["infinity"]=98083086936965,["info"]=124560466474914,["inspection-panel"]=70905313146088,["instagram"]=119864798614855,
["italic"]=96220378864282,["iteration-ccw"]=140221832794083,["iteration-cw"]=95534489554662,["japanese-yen"]=106362863465813,["joystick"]=99416790224739,["kanban"]=125934100055431,
["kayak"]=136107544609389,["key-round"]=83619031955390,["key-square"]=94621420033649,["key"]=96510194465420,["keyboard-music"]=121058541758636,["keyboard-off"]=92466375369772,
["keyboard"]=121474456068237,["lamp-ceiling"]=80032758469141,["lamp-desk"]=85290686983238,["lamp-floor"]=104585881375892,["lamp-wall-down"]=91271394132073,["lamp-wall-up"]=132141464337445,
["lamp"]=110730830653382,["land-plot"]=96449039620294,["landmark"]=76885079756393,["languages"]=90816903776498,["laptop-minimal-check"]=114352019833865,["laptop-minimal"]=136705765566068,
["laptop"]=111387063244975,["lasso-select"]=105609719912753,["lasso"]=121072936884007,["laugh"]=104491311361166,["layers-2"]=70536710516357,["layers"]=81973586053257,
["layout-dashboard"]=139929981863901,["layout-grid"]=81344910161871,["layout-list"]=87462136296578,["layout-panel-left"]=125092469751491,["layout-panel-top"]=91943941515944,["layout-template"]=115564446417985,
["leaf"]=119951075637174,["leafy-green"]=105146290493154,["lectern"]=106166425183862,["library-big"]=106794530191412,["library"]=114334671982047,["life-buoy"]=81168450671956,
["ligature"]=111397873269411,["lightbulb-off"]=83795722296178,["lightbulb"]=103871245626488,["line-squiggle"]=109555164424447,["link-2-off"]=76885956296867,["link-2"]=86072351557466,
["link"]=131607023382430,["linkedin"]=132842789255788,["list-check"]=72374358471156,["list-checks"]=99809353635593,["list-chevrons-down-up"]=137409641500711,["list-chevrons-up-down"]=81825351389084,
["list-collapse"]=124505247702401,["list-end"]=77650610048119,["list-filter-plus"]=96385120752336,["list-filter"]=103321376129527,["list-indent-decrease"]=137879979228193,["list-indent-increase"]=79051053161201,
["list-minus"]=138507965142671,["list-music"]=126380635781840,["list-ordered"]=83212528113913,["list-plus"]=112384738137814,["list-restart"]=91703153577421,["list-start"]=84828348299727,
["list-todo"]=132980603752108,["list-tree"]=97685396239010,["list-video"]=93648525452489,["list-x"]=113025303988861,["list"]=113179976918783,["loader-circle"]=116535712789945,
["loader-pinwheel"]=108513357940900,["loader"]=78408734580845,["locate-fixed"]=137367361548433,["locate-off"]=73729216338137,["locate"]=84467676590391,["lock-keyhole-open"]=110863509313073,
["lock-keyhole"]=78672912777756,["lock-open"]=93597915325122,["lock"]=134724289526879,["log-in"]=103768533135201,["log-out"]=84895399304975,["logs"]=89772091251787,
["lollipop"]=84681611583044,["luggage"]=76619236486400,["magnet"]=135162361226972,["mail-check"]=86921536259917,["mail-minus"]=81989813236553,["mail-open"]=122785416858638,
["mail-plus"]=104886401588341,["mail-question-mark"]=126540170949819,["mail-search"]=135616173775287,["mail-warning"]=81495303676089,["mail-x"]=74607841705644,["mail"]=103945161245599,
["mailbox"]=82765503320335,["mails"]=90673453450080,["map-minus"]=129525760577747,["map-pin-check-inside"]=107130529843809,["map-pin-check"]=118110914690154,["map-pin-house"]=80546885029816,
["map-pin-minus-inside"]=79005529692964,["map-pin-minus"]=74518762643623,["map-pin-off"]=82474689391020,["map-pin-pen"]=113515395277504,["map-pin-plus-inside"]=134639656514430,["map-pin-plus"]=91875228967029,
["map-pin-x-inside"]=126235934252379,["map-pin-x"]=101085273547316,["map-pin"]=84279202219901,["map-pinned"]=103963788475034,["map-plus"]=129388826743495,["map"]=95107167260947,
["mars-stroke"]=131973193186828,["mars"]=111287112372511,["martini"]=82977695401058,["maximize-2"]=73085922906397,["maximize"]=76045941763188,["medal"]=79016002264450,
["megaphone-off"]=124280774193935,["megaphone"]=118759541854879,["meh"]=132197867028557,["memory-stick"]=93212591343119,["menu"]=77021539815611,["merge"]=126201866476775,
["message-circle-code"]=112865244991651,["message-circle-dashed"]=81525157881897,["message-circle-heart"]=101990756073677,["message-circle-more"]=92856823884663,["message-circle-off"]=134955643890328,["message-circle-plus"]=106562979649273,
["message-circle-question-mark"]=107700302759934,["message-circle-reply"]=137071749508334,["message-circle-warning"]=119020096067894,["message-circle-x"]=126843387725536,["message-circle"]=127255077587058,["message-square-code"]=110968863152123,
["message-square-dashed"]=107653455516238,["message-square-diff"]=75472190472625,["message-square-dot"]=127806382463916,["message-square-heart"]=75612811742074,["message-square-lock"]=81268215619563,["message-square-more"]=120139782405970,
["message-square-off"]=99961019005789,["message-square-plus"]=76934450256199,["message-square-quote"]=116670768629340,["message-square-reply"]=130985622754637,["message-square-share"]=131017005324026,["message-square-text"]=94899503194205,
["message-square-warning"]=138432903962261,["message-square-x"]=137285463279462,["message-square"]=83881670383280,["messages-square"]=97532166733358,["mic-off"]=82123034444822,["mic-vocal"]=99082286164362,
["mic"]=89640799126523,["microchip"]=73937907669903,["microscope"]=116875530102782,["microwave"]=108411735353008,["milestone"]=101618292325920,["milk-off"]=72388480962742,
["milk"]=96221903896918,["minimize-2"]=116269596042539,["minimize"]=121304296213645,["minus"]=118026365011536,["monitor-check"]=86651948439229,["monitor-cloud"]=85931096038318,
["monitor-cog"]=94345128715799,["monitor-dot"]=130394010063680,["monitor-down"]=97466933743423,["monitor-off"]=74395526657953,["monitor-pause"]=76002184067562,["monitor-play"]=133018824306217,
["monitor-smartphone"]=84335680433378,["monitor-speaker"]=81744810060380,["monitor-stop"]=98708958984757,["monitor-up"]=96035360858377,["monitor-x"]=126265210441423,["monitor"]=72664649203050,
["moon-star"]=82782200506348,["moon"]=83380517901735,["motorbike"]=94580787368233,["mountain-snow"]=105315495740588,["mountain"]=73269957566415,["mouse-off"]=75267871697595,
["mouse-pointer-2-off"]=104701076865632,["mouse-pointer-2"]=117093892862228,["mouse-pointer-ban"]=106849413057133,["mouse-pointer-click"]=107150227368485,["mouse-pointer"]=72322454962935,["mouse"]=73096068864710,
["move-3d"]=103365982054003,["move-diagonal-2"]=117298577948096,["move-diagonal"]=101433481954184,["move-down-left"]=102819433534567,["move-down-right"]=101479760041877,["move-down"]=70510115135583,
["move-horizontal"]=88513523439149,["move-left"]=137614740247980,["move-right"]=132455779472989,["move-up-left"]=139079815540148,["move-up-right"]=105885140592646,["move-up"]=84505444262658,
["move-vertical"]=86234730730899,["move"]=116138709011735,["music-2"]=134397426600888,["music-3"]=94466120066498,["music-4"]=132459323665838,["music"]=113343203848535,
["navigation-2-off"]=116569611780763,["navigation-2"]=81889066747907,["navigation-off"]=87003270290777,["navigation"]=79308213542922,["network"]=127410729922644,["newspaper"]=123479530460544,
["nfc"]=76822396542242,["non-binary"]=78442360386235,["notebook-pen"]=140380614761023,["notebook-tabs"]=127371085570083,["notebook-text"]=93061585217270,["notebook"]=136132108664987,
["notepad-text-dashed"]=135793446376219,["notepad-text"]=93404682958966,["nut-off"]=78795397311573,["nut"]=127146410705656,["octagon-alert"]=140438367956051,["octagon-minus"]=74720436795421,
["octagon-pause"]=103161463909039,["octagon-x"]=90498161006311,["octagon"]=120803515514852,["omega"]=70414080018786,["option"]=100776883894054,["orbit"]=108926136860562,
["origami"]=136020626667101,["package-2"]=70394974762575,["package-check"]=102374216055130,["package-minus"]=114492858789692,["package-open"]=132890233237818,["package-plus"]=129261988138366,
["package-search"]=95465120894145,["package-x"]=70818501607442,["package"]=97261141732706,["paint-bucket"]=124275586663284,["paint-roller"]=115248074358348,["paintbrush-vertical"]=105151296591292,
["paintbrush"]=125572663700289,["palette"]=86350350950064,["panda"]=132509022802512,["panel-bottom-close"]=74287004071159,["panel-bottom-dashed"]=131084651621603,["panel-bottom-open"]=107768659586540,
["panel-bottom"]=132127145048511,["panel-left-close"]=126579818823552,["panel-left-dashed"]=75536606374585,["panel-left-open"]=111075816195767,["panel-left-right-dashed"]=110100707973959,["panel-left"]=97419752870313,
["panel-right-close"]=139528655524132,["panel-right-dashed"]=94959793877311,["panel-right-open"]=118114419142794,["panel-right"]=116365035443156,["panel-top-bottom-dashed"]=134737235653344,["panel-top-close"]=83578325777808,
["panel-top-dashed"]=70522913169237,["panel-top-open"]=137959875507454,["panel-top"]=75838479462875,["panels-left-bottom"]=72996856149149,["panels-right-bottom"]=90659068960726,["panels-top-left"]=79858853850600,
["paperclip"]=92088291163453,["parentheses"]=78950955173096,["parking-meter"]=84652733960568,["party-popper"]=111626795712193,["pause"]=74873705394436,["paw-print"]=112218825427601,
["pc-case"]=122978648019101,["pen-line"]=109108135755303,["pen-off"]=84807123119438,["pen-tool"]=106145404953445,["pen"]=72037878096321,["pencil-line"]=88392917053533,
["pencil-off"]=103330927652832,["pencil-ruler"]=110120288284597,["pencil"]=137986121120732,["pentagon"]=79184802179890,["percent"]=130155041032013,["person-standing"]=125020872044147,
["philippine-peso"]=91173798254675,["phone-call"]=70555587592860,["phone-forwarded"]=113269614319737,["phone-incoming"]=82863576359288,["phone-missed"]=130156165198376,["phone-off"]=133318623553383,
["phone-outgoing"]=104576478735825,["phone"]=128804946640049,["pi"]=74936036243146,["piano"]=85008880789520,["pickaxe"]=105888023317688,["picture-in-picture-2"]=112803319544468,
["picture-in-picture"]=80579597835123,["piggy-bank"]=79498575790721,["pilcrow-left"]=103803000849583,["pilcrow-right"]=104881733911870,["pilcrow"]=139512780392871,["pill-bottle"]=118394692404597,
["pill"]=73280534813448,["pin-off"]=127696372451750,["pin"]=120978111007514,["pipette"]=133167932934404,["pizza"]=126964453193501,["plane-landing"]=122555692211889,
["plane-takeoff"]=117179478829575,["plane"]=126985561580989,["play"]=135609604299893,["plug-2"]=97912386476366,["plug-zap"]=74506269884055,["plug"]=99782373064495,
["plus"]=111774323017047,["pocket-knife"]=134075428063965,["pocket"]=136686762542964,["podcast"]=109577075549215,["pointer-off"]=95488389312794,["pointer"]=92615117311099,
["popcorn"]=139446511232750,["popsicle"]=112696318077073,["pound-sterling"]=127482649469130,["power-off"]=118768311012214,["power"]=96479131758775,["presentation"]=106134583757890,
["printer-check"]=130273549443689,["printer"]=76080649734247,["projector"]=103281856385283,["proportions"]=130046855997237,["puzzle"]=136837798892463,["pyramid"]=107811442374127,
["qr-code"]=105329945723350,["quote"]=103271711590001,["rabbit"]=98580518804206,["radar"]=138528222906635,["radiation"]=104499586848433,["radical"]=132758286926047,
["radio-receiver"]=129598303378835,["radio-tower"]=93958663130054,["radio"]=85611589536956,["radius"]=89814505307129,["rail-symbol"]=134295386306962,["rainbow"]=132488862841895,
["rat"]=127400975953159,["ratio"]=126369423897295,["receipt-cent"]=91557573925201,["receipt-euro"]=94015722210295,["receipt-indian-rupee"]=89718170439990,["receipt-japanese-yen"]=132472560758851,
["receipt-pound-sterling"]=73934967569625,["receipt-russian-ruble"]=105164576936853,["receipt-swiss-franc"]=72503668620116,["receipt-text"]=138483536013737,["receipt-turkish-lira"]=91950765836342,["receipt"]=77877895901792,
["rectangle-circle"]=100642423153903,["rectangle-ellipsis"]=112919953980965,["rectangle-goggles"]=98605436666727,["rectangle-horizontal"]=90224199814966,["rectangle-vertical"]=117277050590967,["recycle"]=140417023381961,
["redo-2"]=70451039017914,["redo-dot"]=94252981719732,["redo"]=116150342119054,["refresh-ccw-dot"]=106702246753270,["refresh-ccw"]=117913330389477,["refresh-cw-off"]=140179498843054,
["refresh-cw"]=138133190015277,["refrigerator"]=102614042652753,["regex"]=100727200791841,["remove-formatting"]=112833162022628,["repeat-1"]=130144534857095,["repeat-2"]=85927537182704,
["repeat"]=121886242955173,["replace-all"]=127862728198635,["replace"]=128404082279430,["reply-all"]=71723137343562,["reply"]=109788633497028,["rewind"]=95205297521988,
["ribbon"]=94265331526851,["rocket"]=87412317685854,["rocking-chair"]=110420269495360,["roller-coaster"]=112426178972099,["rose"]=126336840238769,["rotate-3d"]=76300551576392,
["rotate-ccw-key"]=74976035240976,["rotate-ccw-square"]=90515853170424,["rotate-ccw"]=110116685948665,["rotate-cw-square"]=77095448159303,["rotate-cw"]=84183336178654,["route-off"]=106350402024079,
["route"]=89968303228953,["router"]=102130331994471,["rows-2"]=112556185960101,["rows-3"]=117215586961375,["rows-4"]=125646021959055,["rss"]=131789058984793,
["ruler-dimension-line"]=70673861371412,["ruler"]=81432445547423,["russian-ruble"]=126357936542156,["sailboat"]=87110567187540,["salad"]=128864507821603,["sandwich"]=104573187458917,
["satellite-dish"]=136742443888305,["satellite"]=134967053164645,["saudi-riyal"]=102282769104635,["save-all"]=116946975799440,["save-off"]=87085435778560,["save"]=126116963775616,
["scale-3d"]=72414199620352,["scale"]=108203682317477,["scaling"]=122360365318466,["scan-barcode"]=96889457154761,["scan-eye"]=99244790601968,["scan-face"]=109959345069668,
["scan-heart"]=106280819776142,["scan-line"]=126544908146540,["scan-qr-code"]=105409149549927,["scan-search"]=80009010551347,["scan-text"]=73702396787766,["scan"]=123104789658180,
["school"]=76351530290068,["scissors-line-dashed"]=122237447974173,["scissors"]=118665510911274,["screen-share-off"]=107677572669805,["screen-share"]=85137895705653,["scroll-text"]=97321022666868,
["scroll"]=74072101474951,["search-check"]=75442076191356,["search-code"]=117114794592802,["search-slash"]=96483932261041,["search-x"]=137319957522951,["search"]=121018724060431,
["section"]=91732188298948,["send-horizontal"]=111734392411664,["send-to-back"]=75340312862253,["send"]=127751956873796,["separator-horizontal"]=84864453699927,["separator-vertical"]=84031801478581,
["server-cog"]=138470287250966,["server-crash"]=132810618000212,["server-off"]=114048751507723,["server"]=92188766517878,["settings-2"]=135684703553372,["settings"]=80758916183665,
["shapes"]=129989433311409,["share-2"]=71210767962065,["share"]=87340985053299,["sheet"]=134902122480171,["shell"]=140212943563599,["shield-alert"]=114995877719925,
["shield-ban"]=108765041044649,["shield-check"]=87354736164608,["shield-ellipsis"]=114794739892123,["shield-half"]=117842634172647,["shield-minus"]=89965059528921,["shield-off"]=133426959132690,
["shield-plus"]=100664857995498,["shield-question-mark"]=135722075265150,["shield-user"]=124832775645347,["shield-x"]=73370117343811,["shield"]=110987169760162,["ship-wheel"]=130797795829448,
["ship"]=83995100553930,["shirt"]=106579555405966,["shopping-bag"]=71885477293226,["shopping-basket"]=138646411956433,["shopping-cart"]=128420521375441,["shovel"]=102465000512056,
["shower-head"]=75884944024117,["shredder"]=122125164414463,["shrimp"]=102625900815307,["shrink"]=90953687918880,["shrub"]=127326280714343,["shuffle"]=132382786975101,
["sigma"]=126884244870899,["signal-high"]=130436670012270,["signal-low"]=73674683500458,["signal-medium"]=125003021367019,["signal-zero"]=130045332414754,["signal"]=78424889355261,
["signature"]=114402748013000,["signpost-big"]=115780185675001,["signpost"]=106584743791433,["siren"]=134210267818039,["skip-back"]=70466132711334,["skip-forward"]=124844823753990,
["skull"]=137726256442333,["slack"]=96089719516736,["slash"]=117792185664263,["slice"]=95810504278179,["sliders-horizontal"]=85538382643347,["sliders-vertical"]=101190569086853,
["smartphone-charging"]=102837532613995,["smartphone-nfc"]=82326425754446,["smartphone"]=96623008834511,["smile-plus"]=131981881472144,["smile"]=105880397565283,["snail"]=70904536548363,
["snowflake"]=101235206534566,["soap-dispenser-droplet"]=77258480479465,["sofa"]=114427687218324,["solar-panel"]=132448188047921,["soup"]=115092551871618,["space"]=87072088914178,
["spade"]=131444449466462,["sparkle"]=111044800239623,["sparkles"]=138635884129147,["speaker"]=96227183003618,["speech"]=87013139446349,["spell-check-2"]=81556731785534,
["spell-check"]=91913483031334,["spline-pointer"]=84842840956804,["spline"]=129406685807412,["split"]=105112438805988,["spool"]=124541981347743,["spotlight"]=77571742539344,
["spray-can"]=128372039366326,["sprout"]=100091687832508,["square-activity"]=89496630185293,["square-arrow-down-left"]=108194680296901,["square-arrow-down-right"]=99403846801050,["square-arrow-down"]=135962519626588,
["square-arrow-left"]=111671474549238,["square-arrow-out-down-left"]=125714881756353,["square-arrow-out-down-right"]=89971003001390,["square-arrow-out-up-left"]=103759986579087,["square-arrow-out-up-right"]=91221896066807,["square-arrow-right"]=113920471701361,
["square-arrow-up-left"]=112424670290693,["square-arrow-up-right"]=76602291406940,["square-arrow-up"]=106998604646718,["square-asterisk"]=89186832353625,["square-bottom-dashed-scissors"]=79076980104803,["square-chart-gantt"]=104034017316411,
["square-check-big"]=115320390907184,["square-check"]=134682053539509,["square-chevron-down"]=91032307924592,["square-chevron-left"]=73143404829510,["square-chevron-right"]=90612077729930,["square-chevron-up"]=85565910197337,
["square-code"]=81604576616881,["square-dashed-bottom-code"]=100354801563230,["square-dashed-bottom"]=101102319625624,["square-dashed-kanban"]=90388067649847,["square-dashed-mouse-pointer"]=121016142178467,["square-dashed-top-solid"]=117157577548540,
["square-dashed"]=136905537847606,["square-divide"]=99894657101970,["square-dot"]=116613421354866,["square-equal"]=110283363706707,["square-function"]=86075219551088,["square-kanban"]=114537101260131,
["square-library"]=73810931222081,["square-m"]=117662700410577,["square-menu"]=104067089444415,["square-minus"]=116764432015770,["square-mouse-pointer"]=76141850603920,["square-parking-off"]=100857293535141,
["square-parking"]=133116656122387,["square-pause"]=86608552787615,["square-pen"]=120239476110475,["square-percent"]=87111930314567,["square-pi"]=75383328781618,["square-pilcrow"]=131854284699367,
["square-play"]=108186325238481,["square-plus"]=114713264461873,["square-power"]=129240437805187,["square-radical"]=132645931868292,["square-round-corner"]=104592745113567,["square-scissors"]=110601255612411,
["square-sigma"]=113231244246816,["square-slash"]=105477013908757,["square-split-horizontal"]=76095370148660,["square-split-vertical"]=88589192032058,["square-square"]=136555087357875,["square-stack"]=100463396619394,
["square-star"]=94506958703720,["square-stop"]=80018708472943,["square-terminal"]=83969264476798,["square-user-round"]=86484997229302,["square-user"]=70771214183445,["square-x"]=125136183850190,
["square"]=86304921356806,["squares-exclude"]=102345385822324,["squares-intersect"]=120869602570119,["squares-subtract"]=131484650948795,["squares-unite"]=96673080107843,["squircle-dashed"]=129936702532522,
["squircle"]=82426632573807,["squirrel"]=112864252085343,["stamp"]=92370779813368,["star-half"]=117449275562979,["star-off"]=75742832732503,["star"]=136141469398409,
["step-back"]=108672750005121,["step-forward"]=126131872136145,["stethoscope"]=122331031702148,["sticker"]=79938203791608,["sticky-note"]=111894074643919,["store"]=90338129673705,
["stretch-horizontal"]=87665042192343,["stretch-vertical"]=95265463417122,["strikethrough"]=103417324549613,["subscript"]=74553514785183,["sun-dim"]=129141645592715,["sun-medium"]=130278807964710,
["sun-moon"]=75752898854559,["sun-snow"]=112791898014579,["sun"]=110150589884127,["sunrise"]=134705665494098,["sunset"]=75904872203588,["superscript"]=96887696590118,
["swatch-book"]=126786244872453,["swiss-franc"]=113497920041625,["switch-camera"]=76841154349737,["sword"]=124448418211665,["swords"]=81872698913435,["syringe"]=123891270479254,
["table-2"]=95751552281545,["table-cells-merge"]=95363715175258,["table-cells-split"]=114799086088649,["table-columns-split"]=111011625447949,["table-of-contents"]=135044763275414,["table-properties"]=125062886015372,
["table-rows-split"]=96443733673997,["table"]=109109148250737,["tablet-smartphone"]=133680859813404,["tablet"]=128403991264386,["tablets"]=80835787970735,["tag"]=129104970103940,
["tags"]=107179263080798,["tally-1"]=115301298241643,["tally-2"]=110363186864027,["tally-3"]=97655344572540,["tally-4"]=102633494371890,["tally-5"]=88031817475886,
["tangent"]=123263132981724,["target"]=87563802520297,["telescope"]=91755049143647,["tent-tree"]=76698322463977,["tent"]=109779587826330,["terminal"]=106783148545356,
["test-tube-diagonal"]=75662704378840,["test-tube"]=98801015650164,["test-tubes"]=92555361447433,["text-align-center"]=84051028246390,["text-align-end"]=130041738343555,["text-align-justify"]=80279880143030,
["text-align-start"]=134489585487649,["text-cursor-input"]=107551944047171,["text-cursor"]=115984654447300,["text-initial"]=129458097472087,["text-quote"]=139278366448736,["text-search"]=92345384671606,
["text-select"]=117087320884956,["text-wrap"]=114804318314018,["theater"]=108558145549163,["thermometer-snowflake"]=121876188028425,["thermometer-sun"]=106693240074310,["thermometer"]=106546011492311,
["thumbs-down"]=87794009914015,["thumbs-up"]=111137070767020,["ticket-check"]=105428777212507,["ticket-minus"]=78966299769328,["ticket-percent"]=80834774406405,["ticket-plus"]=110086734392189,
["ticket-slash"]=89045681172265,["ticket-x"]=88674114109926,["ticket"]=126527071492145,["tickets-plane"]=100367018248695,["tickets"]=135268612687833,["timer-off"]=110916370767271,
["timer-reset"]=110052125369932,["timer"]=85473888890506,["toggle-left"]=85887872573050,["toggle-right"]=90411952142550,["toilet"]=80930782432931,["tool-case"]=87533537832522,
["tornado"]=88358291515768,["torus"]=70855707283051,["touchpad-off"]=78784008075456,["touchpad"]=74882354908014,["tower-control"]=95937619060532,["toy-brick"]=86293483924633,
["tractor"]=103376704722051,["traffic-cone"]=74110220470369,["train-front-tunnel"]=105194827005114,["train-front"]=125237934215370,["train-track"]=77451032453723,["tram-front"]=93315182364998,
["transgender"]=135530817673639,["trash-2"]=109843431391323,["trash"]=106723740584310,["tree-deciduous"]=123124389219004,["tree-palm"]=103846705893963,["tree-pine"]=124662547202594,
["trees"]=121203841375919,["trello"]=130987241149527,["trending-down"]=139309232226438,["trending-up-down"]=85083293981691,["trending-up"]=81819858538839,["triangle-alert"]=125920361880643,
["triangle-dashed"]=124324079103935,["triangle-right"]=116930791412791,["triangle"]=126330486745540,["trophy"]=131545003268773,["truck-electric"]=111873446387359,["truck"]=86662707764771,
["turkish-lira"]=114589876174070,["turntable"]=129870346487856,["turtle"]=118295081560334,["tv-minimal-play"]=99201833426972,["tv-minimal"]=100382201729427,["tv"]=135687724791776,
["twitch"]=71383308134888,["twitter"]=88791703276842,["type-outline"]=80108627791690,["type"]=133543553793564,["umbrella-off"]=72395143739955,["umbrella"]=127502210274589,
["underline"]=123709229216544,["undo-2"]=113885292059932,["undo-dot"]=132055277744844,["undo"]=111258459077271,["unfold-horizontal"]=117128358526398,["unfold-vertical"]=116593025265499,
["ungroup"]=106674800451003,["university"]=84652528263642,["unlink-2"]=128131898892572,["unlink"]=139835795227752,["unplug"]=90171381619874,["upload"]=138212042425501,
["usb"]=117230058949613,["user-check"]=81775205032725,["user-cog"]=92795491530865,["user-lock"]=78892639693821,["user-minus"]=126976941957511,["user-pen"]=87445472574836,
["user-plus"]=118514469915884,["user-round-check"]=118794737621941,["user-round-cog"]=78239503290053,["user-round-minus"]=98944176636447,["user-round-pen"]=108155244324878,["user-round-plus"]=113301899567470,
["user-round-search"]=71565774381870,["user-round-x"]=122367980560930,["user-round"]=136485052187963,["user-search"]=101335649828115,["user-star"]=98777846316000,["user-x"]=139748155894754,
["user"]=81589895647169,["users-round"]=103005444008339,["users"]=115398113982385,["utensils-crossed"]=109520762270383,["utensils"]=139952569804235,["utility-pole"]=101965541238242,
["variable"]=104743088438151,["vault"]=108049164599845,["vector-square"]=86713728565344,["vegan"]=119489190688082,["venetian-mask"]=102636443033920,["venus-and-mars"]=120227752103771,
["venus"]=82891342220859,["vibrate-off"]=113446447326246,["vibrate"]=108330910738733,["video-off"]=132239189859305,["video"]=107587444636945,["videotape"]=114816894323398,
["view"]=118717253976805,["voicemail"]=134313454010227,["volleyball"]=83889351124153,["volume-1"]=98514588731639,["volume-2"]=89344380902620,["volume-off"]=103047478058767,
["volume-x"]=139252359189540,["volume"]=103236289817396,["vote"]=89409762851246,["wallet-cards"]=129728715308337,["wallet-minimal"]=137800448816116,["wallet"]=132331555762628,
["wallpaper"]=74682121235494,["wand-sparkles"]=82546429942392,["wand"]=114580617777835,["warehouse"]=78388887451080,["washing-machine"]=104194127573858,["watch"]=130544621618405,
["waves-ladder"]=101808619355514,["waves"]=96340135183647,["waypoints"]=102450133666017,["webcam"]=104148487911129,["webhook-off"]=96370548093471,["webhook"]=112812457747322,
["weight"]=103860559844854,["wheat-off"]=133294844612307,["wheat"]=85261952080359,["whole-word"]=90111083954485,["wifi-cog"]=110500263326209,["wifi-high"]=81954601342139,
["wifi-low"]=138217335635913,["wifi-off"]=74113634330106,["wifi-pen"]=91290205064712,["wifi-sync"]=84043971055177,["wifi-zero"]=124286465246123,["wifi"]=104669375183960,
["wind-arrow-down"]=127753987414870,["wind"]=114551690399915,["wine-off"]=108294164302317,["wine"]=115743721332829,["workflow"]=99186544029189,["worm"]=115752311548091,
["wrench"]=112148279212860,["x"]=110786993356448,["youtube"]=123663668456341,["zap-off"]=81385483183652,["zap"]=130551565616516,["zoom-in"]=127956924984803,
["zoom-out"]=108334162607319,["balloon"]=97489111621526,["beef-off"]=99869959725200,["book-search"]=132585409504950,["calendars"]=130944763042289,["cannabis-off"]=101938500363812,
["cctv-off"]=75925370187295,["cigarette"]=137149549886852,["circle-pile"]=116353155251541,["cloud-backup"]=111649579696132,["cloud-sync"]=79393911188593,["database-search"]=92017137080138,
["ellipse"]=71559658267482,["fingerprint-pattern"]=80934710831288,["fishing-hook"]=121038780855899,["fishing-rod"]=71754848048049,["form"]=72999643971000,["git-merge-conflict"]=85677801675703,
["globe-off"]=77775243585824,["globe-x"]=109268097029296,["hd"]=71682790698278,["image"]=112751259236831,["layers-plus"]=77587765623057,["lens-concave"]=94819631937027,
["lens-convex"]=74736504195474,["line-dot-right-horizontal"]=104718593155221,["line-style"]=90176717785772,["map-pin-search"]=89065012915078,["message-circle-check"]=132772297689418,["message-square-check"]=125789987055668,
["metronome"]=101991829345965,["mirror-rectangular"]=109046769760336,["mirror-round"]=121534049429097,["mouse-left"]=99144293708743,["mouse-right"]=88331710212594,["printer-x"]=103002721801548,
["radio-off"]=80359258046586,["road"]=120251329173530,["scooter"]=100035452787934,["search-alert"]=127597984617505,["shelving-unit"]=80116568514793,["shield-cog-corner"]=111694066132698,
["shield-cog"]=129235695057857,["sport-shoe"]=120495992692630,["square-arrow-right-enter"]=138867831495334,["square-arrow-right-exit"]=133688575845430,["square-centerline-dashed-horizontal"]=77780104374341,["square-centerline-dashed-vertical"]=107878435803525,
["stone"]=135161057497830,["toolbox"]=85341033903792,["towel-rack"]=125223915620991,["user-key"]=105403041782190,["user-round-key"]=124547549008939,["van"]=122066377022942,
["waves-arrow-down"]=129215220911792,["waves-arrow-up"]=102314705716217,["weight-tilde"]=112081212176951,["x-line-top"]=140592656289509,["zodiac-aquarius"]=74560047770362,["zodiac-aries"]=73255859670234,
["zodiac-cancer"]=131985162532947,["zodiac-capricorn"]=97859568140652,["zodiac-gemini"]=80997588122992,["zodiac-leo"]=75509406718106,["zodiac-libra"]=113222735060218,["zodiac-ophiuchus"]=129180108892480,
["zodiac-pisces"]=95845819440327,["zodiac-sagittarius"]=82651026742181,["zodiac-scorpio"]=113640924054631,["zodiac-taurus"]=123053219704400,["zodiac-virgo"]=99462994613661,
}
end
__modules["inbox"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local HEADER=44
return function(Window)
function Window:_buildInbox()
if self.cfg.NotificationHistory==false then return end
local Lib=self.Lib
local button=self._windowButton("Inbox",self:_headerSlot(),false,true)
local parts={}
local function part(props,radius)
local object=create("Frame",props)
object.BorderSizePixel=0
object.Parent=button
if radius then corner(object,radius)end
Theme.bind(object,"BackgroundColor3","muted")
parts[#parts+1]=object
return object
end
part({AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,8),Size=UDim2.fromOffset(8,9)},4)
part({AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,15),Size=UDim2.fromOffset(12,2)},1)
part({AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,18),Size=UDim2.fromOffset(3,2)},1)
local dot=create("Frame",{Name="Unread",Position=UDim2.new(0.5,3,0,6),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Visible=false,ZIndex=3,Parent=button})
corner(dot,3)
Theme.bind(dot,"BackgroundColor3","accent")
Theme.bind(stroke(dot,nil,0,1.5),"Color","base")
button.MouseEnter:Connect(function()for _,p in ipairs(parts)do Theme.tweenTo(p,"BackgroundColor3","heading",0.12)end end)
button.MouseLeave:Connect(function()for _,p in ipairs(parts)do Theme.tweenTo(p,"BackgroundColor3","muted",0.12)end end)
local seen=0
local panel
local function unread()
local history=Lib.NotifyHistory or{}
local count=0
for _,entry in ipairs(history)do if entry.Time and entry._id and entry._id>seen then count=count+1 end end
return count
end
local nextId=0
local function stamp()
for index=#(Lib.NotifyHistory or{}),1,-1 do
local entry=Lib.NotifyHistory[index]
if not entry._id then nextId=nextId+1 entry._id=nextId end
end
end
local function close()
if panel then panel:Destroy()panel=nil end
end
local function render()
if not panel then return end
local list=panel:FindFirstChild("List")
for _,child in ipairs(list:GetChildren())do if child:IsA("GuiObject")then child:Destroy()end end
local history=Lib.NotifyHistory or{}
panel:FindFirstChild("Empty").Visible=#history==0
for index,entry in ipairs(history)do
local item=create("Frame",{Name="Entry",BackgroundTransparency=1,Size=UDim2.new(1,0,0,entry.Content and 38 or 24),LayoutOrder=index,ZIndex=232,Parent=list})
local mark=create("Frame",{Position=UDim2.fromOffset(0,5),Size=UDim2.new(0,2,1,-10),BorderSizePixel=0,ZIndex=233,Parent=item})
corner(mark,1)
Theme.bind(mark,"BackgroundColor3",entry.Color or"accent")
local entryIcon=entry.Icon and Icons.themed(item,entry.Icon,12,"accent",{Position=UDim2.fromOffset(10,5),ZIndex=233})
if entryIcon and entry.Color then Theme.bind(entryIcon,"ImageColor3",entry.Color)end
local title=label(item,entry.Title..((entry.Count or 1)>1 and("  ×"..entry.Count)or""),10,{Position=UDim2.fromOffset(entryIcon and 28 or 10,3),Size=UDim2.new(1,entryIcon and-82 or-64,0,16),Font=Enum.Font.GothamMedium,ZIndex=233})
Theme.bind(title,"TextColor3","heading")
local time=label(item,Util.ago(entry.Time),9,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,3),Size=UDim2.fromOffset(54,16),TextXAlignment=Enum.TextXAlignment.Right,ZIndex=233})
Theme.bind(time,"TextColor3","muted")
if entry.Content then
local content=label(item,entry.Content,9,{Position=UDim2.fromOffset(entryIcon and 28 or 10,19),Size=UDim2.new(1,entryIcon and-28 or-10,0,14),ZIndex=233})
Theme.bind(content,"TextColor3","muted")
end
end
end
function self:OpenInbox()
close()
stamp()
panel=create("Frame",{
Name="InboxPanel",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,HEADER-4),Size=UDim2.fromOffset(270,260),
BorderSizePixel=0,ZIndex=230,Active=true,Parent=self.main,
})
Theme.bind(panel,"BackgroundColor3","card")
corner(panel,8)
Theme.bind(stroke(panel),"Color","line")
local heading=label(panel,"Notifications",11,{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-90,0,20),Font=Enum.Font.GothamMedium,ZIndex=231})
Theme.bind(heading,"TextColor3","heading")
local clear=create("TextButton",{
Name="Clear",Text="Clear",TextSize=9,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,9),Size=UDim2.fromOffset(44,18),ZIndex=231,Parent=panel,
})
Theme.bind(clear,"BackgroundColor3","input")
Theme.bind(clear,"TextColor3","text")
corner(clear,5)
Theme.bind(stroke(clear),"Color","buttonEdge")
clear.Activated:Connect(function()self:ClearInbox()end)
local line=create("Frame",{Position=UDim2.fromOffset(12,34),Size=UDim2.new(1,-24,0,1),BorderSizePixel=0,ZIndex=231,Parent=panel})
Theme.bind(line,"BackgroundColor3","line")
local list=create("ScrollingFrame",{
Name="List",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(14,40),Size=UDim2.new(1,-22,1,-48),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollingDirection=Enum.ScrollingDirection.Y,
ZIndex=231,Parent=panel,
})
Theme.bind(list,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(list)
Util.fitCanvas(list,Util.list(list,2))
local empty=label(panel,"No notifications yet",10,{Name="Empty",Position=UDim2.fromOffset(0,40),Size=UDim2.new(1,0,1,-48),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=231})
Theme.bind(empty,"TextColor3","muted")
render()
seen=nextId
dot.Visible=false
self:_openPopup(panel,button,close)
end
function self:ClearInbox()
Lib.NotifyHistory={}
render()
dot.Visible=false
end
button.Activated:Connect(function()
if panel then self:_closePopup()else self:OpenInbox()end
end)
Lib._historyListeners=Lib._historyListeners or{}
local function listener()
if not self.alive then return end
stamp()
if panel then render()seen=nextId else dot.Visible=unread()>0 end
end
table.insert(Lib._historyListeners,listener)
self.maid:give(function()
local index=table.find(Lib._historyListeners,listener)
if index then table.remove(Lib._historyListeners,index)end
end)
self.inboxButton=button
end
end
end
__modules["init"]=function()
local Util=require("util")
local Theme=require("theme")
local Window=require("window")
local Notify=require("notify")
local Settings=require("settings")
local Dashboard=require("dashboard")
local Icons=require("icons")
local Sounds=require("sounds")
local Gate=require("gate")
require("status")(Window)
require("dialog")(Window)
require("hud")(Window)
require("inbox")(Window)
require("windowx")(Window)
require("windowfx")(Window)
require("kick")(Window)
require("mobile")(Window)
require("tour")(Window)
local Lib={
Version="1.9.2",
Flags={},
Windows={},
Theme=Theme,
Icons=Icons,
Sounds=Sounds,
Haptics=require("haptics"),
Util=Util,
}
Lib.maid=Util.maid()
function Lib:CreateWindow(cfg)
cfg=cfg or{}
if cfg.Secure then Util.secure=true end
if type(cfg.KeySystem)=="table"and not Gate.run(self,cfg)then
error("[qustah-ui-lib] no key entered - the script was stopped",0)
end
return Window.new(self,cfg)
end
function Lib:ForgetKey(folder)Gate.forget(folder)end
function Lib:Notify(cfg)return Notify.show(self,cfg)end
function Lib:Toast(cfg)return Notify.pill(self,cfg)end
Lib.MaxNotifications=6
function Lib:SetAccent(color)Theme.set("accent",color)end
function Lib:SetColor(role,color)Theme.set(role,color)end
function Lib:GetFlag(flag)return self.Flags[flag]end
function Lib:SetSecure(on)Util.secure=on~=false end
function Lib:IsSecure()return Util.secure==true end
function Lib:Destroy()
for index=#self.Windows,1,-1 do self.Windows[index]:Destroy()end
self.maid:clean()
end
local function builtIn(window,build,cfg)
window._noAutoFlags=true
local ok,result=pcall(build,window,cfg)
window._noAutoFlags=nil
if not ok then error(result,0)end
return result
end
function Window:SettingsTab(cfg)return builtIn(self,Settings,cfg)end
function Window:DashboardTab(cfg)return builtIn(self,Dashboard,cfg)end
return Lib
end
__modules["kick"]=function()
local Util=require("util")
local KINDS={
[267]="Kicked",[268]="Unexpected client behaviour",[273]="Logged in elsewhere",[274]="Server shut down",
[277]="Connection lost",[278]="Idle (AFK) disconnect",[279]="Failed to connect",[282]="Disconnected",
[292]="Game removed",[517]="Server full",[524]="Not allowed",[529]="Service error",[600]="Banned",
}
local function parse(message,code)
message=tostring(message or"")
code=tonumber(code)or tonumber(message:match("[Ee]rror [Cc]ode:?%s*(%d+)"))
local reason=message:match("[Kk]icked from this [%a]+:%s*(.-)%s*%(?[Ee]rror [Cc]ode")
or message:match("[Kk]icked from this [%a]+:%s*(.+)$")
or message:match("^(.-)%s*%(?[Ee]rror [Cc]ode")or message
reason=reason:gsub("%s+$",""):gsub("^%s+","")
if reason==""then reason=KINDS[code]or"Disconnected"end
return{Reason=reason,Code=code,Kind=KINDS[code]or(code and("Error "..code))or"Disconnected",Message=message,Time=os.time()}
end
return function(Window)
Window._parseKick=parse
function Window:OnKick(callback)
self._kickListeners=self._kickListeners or{}
table.insert(self._kickListeners,callback)
end
function Window:GetKicks()
local data=self.Config:ReadJSON("kicks")
return type(data.list)=="table"and data.list or{}
end
function Window:_kicked(message,code)
local info=parse(message,code)
if self.LastKick and self.LastKick.Message==info.Message and os.time()-self.LastKick.Time<10 then return end
self.LastKick=info
local list=self:GetKicks()
table.insert(list,1,{Reason=info.Reason,Code=info.Code,Kind=info.Kind,Time=info.Time,Place=game.PlaceId})
while#list>20 do table.remove(list)end
self.Config:WriteJSON("kicks",{list=list})
for _,listener in ipairs(self._kickListeners or{})do self:_safe("OnKick",listener,info)end
if self.cfg.Rejoin and info.Code~=273 and info.Code~=600 then
task.delay(tonumber(self.cfg.RejoinDelay)or 2,function()
pcall(function()Util.Services.TeleportService:Teleport(game.PlaceId,Util.Services.Players.LocalPlayer)end)
end)
end
end
function Window:_watchKicks()
if self.cfg.KickLog==false then return end
local GuiService=Util.Services.GuiService
pcall(function()
self.maid:connect(GuiService.ErrorMessageChanged,function(message)
if not message or message==""then return end
local code
pcall(function()code=GuiService:GetErrorCode().Value end)
self:_kicked(message,code)
end)
end)
task.spawn(function()
pcall(function()
local prompt=Util.Services.CoreGui:FindFirstChild("RobloxPromptGui")
local overlay=prompt and prompt:FindFirstChild("promptOverlay")
if not overlay then return end
self.maid:connect(overlay.ChildAdded,function(child)
if child.Name~="ErrorPrompt"then return end
task.wait(0.1)
local text=child:FindFirstChild("ErrorMessage",true)
if text and text.Text~=""then self:_kicked(text.Text)end
end)
end)
end)
end
end
end
__modules["mobile"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
return function(Window)
function Window:SetMobileButton(on,remember)
self.mobileButton=on==true
if remember and self.memory then self.memory.mobileButton=self.mobileButton self:_saveMemory()end
if self.mobileButton and not self._pill then self:_makePill()end
self:_showPill()
end
function Window:_showPill()
local pill=self._pill
if not pill then return end
local show=self.mobileButton and self.alive and not self.visible
if show then
pill.Visible=true
tween(pill,0.18,{GroupTransparency=0})
else
tween(pill,0.12,{GroupTransparency=1})
task.delay(0.13,function()
if pill.Parent and not(self.mobileButton and self.alive and not self.visible)then pill.Visible=false end
end)
end
end
function Window:_makePill()
local pill=create("CanvasGroup",{
Name="MobileButton",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,40),BorderSizePixel=0,
GroupTransparency=1,Visible=false,ZIndex=80,Parent=self.gui,
})
Theme.bind(pill,"BackgroundColor3","base")
corner(pill,20)
local edge=stroke(pill,nil,0.3)
Theme.bind(edge,"Color","accentEdge")
local row=create("Frame",{Name="Row",BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromScale(0,1),Parent=pill})
Util.list(row,8,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
Util.padding(row,12,16,0,0)
Icons.themed(row,self.cfg.Icon or self.cfg.MobileIcon or"menu",16,"accent",{Name="Icon",LayoutOrder=1})
local text=label(row,self.Title,12,{Name="Text",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,40),Font=Enum.Font.GothamMedium,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2})
Theme.bind(text,"TextColor3","heading")
create("UISizeConstraint",{MaxSize=Vector2.new(150,40),Parent=text})
local hit=create("TextButton",{Name="Hit",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=81,Parent=pill})
self._pill=pill
local saved=self.memory and self.memory.mobilePill
local fraction=type(saved)=="table"and Vector2.new(tonumber(saved[1])or 0.5,tonumber(saved[2])or 0.1)or Vector2.new(0.5,0.1)
local function place()
local viewport=Util.viewport()
local room=Vector2.new(math.max(0,viewport.X-pill.AbsoluteSize.X),math.max(0,viewport.Y-pill.AbsoluteSize.Y))
pill.Position=UDim2.fromOffset(math.floor(fraction.X*room.X),math.floor(fraction.Y*room.Y))
end
self.maid:connect(pill:GetPropertyChangedSignal("AbsoluteSize"),place)
self._placers=self._placers or{}
table.insert(self._placers,place)
place()
hit.InputBegan:Connect(function(input)
if not Util.isPress(input)then return end
local start=Util.pointer(input)
local origin=Vector2.new(pill.Position.X.Offset,pill.Position.Y.Offset)
local dragged=false
self:_beginDrag(input,function(point)
local delta=point-start
if not dragged and delta.Magnitude<6 then return end
dragged=true
local viewport=Util.viewport()
local room=Vector2.new(math.max(1,viewport.X-pill.AbsoluteSize.X),math.max(1,viewport.Y-pill.AbsoluteSize.Y))
local target=origin+delta
fraction=Vector2.new(math.clamp(target.X/room.X,0,1),math.clamp(target.Y/room.Y,0,1))
place()
end,function()
if dragged then
self.memory.mobilePill={fraction.X,fraction.Y}
self:_saveMemory()
else
require("haptics").Play("click")
self:SetVisible(true)
end
end)
end)
end
local setVisible=Window.SetVisible
function Window:SetVisible(visible)
setVisible(self,visible)
if self._pill then self:_showPill()end
end
function Window:_buildMobile()
local mode=self.cfg.MobileButton
if mode==nil then mode="Auto"end
local saved=self.memory and self.memory.mobileButton
if saved~=nil then mode=saved end
local on=mode==true or(mode=="Auto"and Util.isTouch())
if on then self:SetMobileButton(true)end
self.maid:give(function()if self._pill then self._pill:Destroy()end end)
end
end
end
__modules["notify"]=function()
local Util=require("util")
local Theme=require("theme")
local UIFont=require("font")
local Icons=require("icons")
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
local Notify={}
function Notify.holder(Lib)
if Lib._notifyHolder and Lib._notifyHolder.Parent then return Lib._notifyHolder end
local gui=Util.screenGui("QustahUI_Notifications",60)
Lib.maid:give(gui)
UIFont.register(gui,Lib.maid)
local holder=create("Frame",{
Name="Toasts",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),
Size=UDim2.new(0,250,1,-32),Parent=gui,
})
Util.list(holder,6,nil,nil,Enum.VerticalAlignment.Bottom)
Lib._notifyHolder=holder
return holder
end
function Notify.show(Lib,cfg)
if type(cfg)=="string"then cfg={Title=cfg}end
cfg=cfg or{}
local holder=Notify.holder(Lib)
local simple=cfg.Merge~=false and not(type(cfg.Buttons)=="table"and#cfg.Buttons>0)and cfg.Progress==nil and cfg.Steps==nil and cfg.Persist~=true
local mergeKey=simple and(tostring(cfg.Title or"").."\0"..tostring(cfg.Content or""))or nil
if mergeKey then
for _,item in ipairs(Lib._openToasts or{})do
if item.key==mergeKey and item.handle and item.handle:IsOpen()then
item.bump()
local last=Lib.NotifyHistory and Lib.NotifyHistory[1]
if last and last.Title==tostring(cfg.Title or"")and last.Content==(cfg.Content and tostring(cfg.Content)or nil)then
last.Count=(last.Count or 1)+1
last.Time=os.time()
for _,listener in ipairs(Lib._historyListeners or{})do Util.safe(listener)end
end
return item.handle
end
end
end
require("haptics").Play("notify")
if cfg.History~=false then
Lib.NotifyHistory=Lib.NotifyHistory or{}
table.insert(Lib.NotifyHistory,1,{Title=tostring(cfg.Title or""),Content=cfg.Content and tostring(cfg.Content)or nil,Color=cfg.Color,Icon=cfg.Icon,Time=os.time()})
while#Lib.NotifyHistory>50 do table.remove(Lib.NotifyHistory)end
for _,listener in ipairs(Lib._historyListeners or{})do Util.safe(listener)end
end
Lib._toastOrder=(Lib._toastOrder or 0)+1
local length=#tostring(cfg.Title or"")+#tostring(cfg.Content or"")
local duration=tonumber(cfg.Duration)or math.clamp(2.5+length*0.045,3,10)
local tracked=cfg.Progress~=nil or cfg.Steps~=nil or cfg.Persist==true
local hasContent=(cfg.Content~=nil and cfg.Content~="")or cfg.Steps~=nil
local buttons=type(cfg.Buttons)=="table"and#cfg.Buttons>0 and cfg.Buttons or nil
if buttons and not cfg.Duration then duration=math.max(duration,6)end
local textHeight=hasContent and 50 or 34
local height=textHeight+(buttons and 32 or 0)
local toast=create("CanvasGroup",{
Name="Toast",Size=UDim2.new(1,0,0,height),BorderSizePixel=0,GroupTransparency=1,
LayoutOrder=Lib._toastOrder,Parent=holder,
})
Theme.bind(toast,"BackgroundColor3","card")
corner(toast,8)
Theme.bind(stroke(toast),"Color","line")
local marker=create("Frame",{Position=UDim2.fromOffset(12,10),Size=UDim2.new(0,3,0,textHeight-20),BorderSizePixel=0,Parent=toast})
corner(marker,2)
local progress=create("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BorderSizePixel=0,Parent=toast})
local tint=(typeof(cfg.Color)=="Color3"or type(cfg.Color)=="string")and cfg.Color or"accent"
Theme.bind(marker,"BackgroundColor3",tint)
Theme.bind(progress,"BackgroundColor3",tint)
local textX=23
local icon=cfg.Icon and Icons.Get(cfg.Icon)and Icons.Image(cfg.Icon,{Name="ToastIcon",Size=UDim2.fromOffset(16,16)})
if icon then
marker.Visible=false
icon.AnchorPoint=Vector2.new(0,0.5)
icon.Position=UDim2.new(0,12,0,textHeight/2)
Theme.bind(icon,"ImageColor3",tint)
icon.Parent=toast
textX=36
end
local closeRoom=cfg.CanClose~=false and 22 or 0
local contentLabel
local title=label(toast,tostring(cfg.Title or""),11,{Position=UDim2.fromOffset(textX,hasContent and 8 or 0),Size=UDim2.new(1,-textX-9-closeRoom,0,hasContent and 17 or textHeight),Font=Enum.Font.GothamBold})
Theme.bind(title,"TextColor3","heading")
if hasContent then
contentLabel=label(toast,tostring(cfg.Content or""),10,{Name="Content",Position=UDim2.fromOffset(textX,25),Size=UDim2.new(1,-textX-9-closeRoom,0,16)})
Theme.bind(contentLabel,"TextColor3","muted")
end
local closed=false
local timer
local entry={toast=toast,key=mergeKey,count=1}
local function dismiss()
if closed or not toast.Parent then return end
closed=true
if timer then timer:Disconnect()timer=nil end
for index,item in ipairs(Lib._openToasts or{})do if item==entry then table.remove(Lib._openToasts,index)break end end
tween(toast,0.25,{GroupTransparency=1})
task.delay(0.27,function()if toast.Parent then toast:Destroy()end end)
end
entry.dismiss=dismiss
Lib._openToasts=Lib._openToasts or{}
table.insert(Lib._openToasts,entry)
local limit=math.max(1,tonumber(Lib.MaxNotifications)or 6)
while#Lib._openToasts>limit do table.remove(Lib._openToasts,1).dismiss()end
local room=Util.viewport().Y-32
local used=height
for index=#Lib._openToasts-1,1,-1 do
local item=Lib._openToasts[index]
local h=item.toast.Parent and item.toast.Size.Y.Offset or 0
if used+h+6>room then
for _=1,index do table.remove(Lib._openToasts,1).dismiss()end
break
end
used=used+h+6
end
local hovered=false
toast.MouseEnter:Connect(function()hovered=true end)
toast.MouseLeave:Connect(function()hovered=false end)
if cfg.CanClose~=false then
local close=create("TextButton",{
Name="Close",Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),
Position=UDim2.new(1,-6,0,6),Size=UDim2.fromOffset(18,18),Parent=toast,
})
for _,rotation in ipairs({45,-45})do
local bar=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(9,1.5),Rotation=rotation,BorderSizePixel=0,Parent=close})
Theme.bind(bar,"BackgroundColor3","muted")
end
close.Activated:Connect(dismiss)
end
if buttons then
local row=create("Frame",{Name="Buttons",BackgroundTransparency=1,Position=UDim2.new(0,textX,0,textHeight-4),Size=UDim2.new(1,-textX-10,0,24),Parent=toast})
Util.list(row,6,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
for index,spec in ipairs(buttons)do
local text=tostring(spec.Title or"OK")
local button=create("TextButton",{
Name=text,Text=text,TextSize=9,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
Size=UDim2.fromOffset(Util.textWidth(text,9,Enum.Font.GothamMedium)+20,22),LayoutOrder=index,Parent=row,
})
corner(button,6)
local outline=stroke(button)
if spec.Style=="Primary"or index==1 then
Theme.bind(button,"BackgroundColor3","accentDeep")
Theme.bind(button,"TextColor3","accent")
Theme.bind(outline,"Color","accent")
outline.Transparency=0.5
else
Theme.bind(button,"BackgroundColor3","input")
Theme.bind(button,"TextColor3","text")
Theme.bind(outline,"Color","buttonEdge")
end
button.Activated:Connect(function()
Util.safe(spec.Callback)
if spec.Close~=false then dismiss()end
end)
end
end
tween(toast,0.2,{GroupTransparency=0})
if cfg.Sound then
pcall(function()
local sound=Instance.new("Sound")
sound.SoundId=cfg.Sound==true and"rbxasset://sounds/electronicpingshort.wav"or(tostring(cfg.Sound):match("^%d+$")and("rbxassetid://"..cfg.Sound)or tostring(cfg.Sound))
sound.Volume=tonumber(cfg.Volume)or 0.4
sound.Parent=Util.Services.SoundService
sound:Play()
task.delay(4,function()sound:Destroy()end)
end)
end
local handle={Frame=toast}
local steps=tonumber(cfg.Steps)
function handle:SetTitle(text)title.Text=tostring(text)end
function handle:SetContent(text)if contentLabel then contentLabel.Text=tostring(text)end end
function handle:SetProgress(value)
value=math.clamp(tonumber(value)or 0,0,1)
self.Progress=value
tween(progress,0.2,{Size=UDim2.new(value,0,0,2)})
if value>=1 then task.delay(1.2,dismiss)end
end
function handle:SetStep(step,text)
step=tonumber(step)or 0
self.Step=step
if contentLabel then contentLabel.Text=string.format("%d/%d%s",math.min(step,steps or step),steps or step,text and("  ·  "..tostring(text))or"")end
if steps and steps>0 then self:SetProgress(step/steps)end
end
function handle:Close()dismiss()end
function handle:IsOpen()return not closed and toast.Parent~=nil end
if tracked then
progress.Size=UDim2.new(0,0,0,2)
if steps then handle:SetStep(tonumber(cfg.Step)or 0,cfg.Content)elseif cfg.Progress then handle:SetProgress(cfg.Progress)end
end
local remaining=duration
function entry.bump()
entry.count=entry.count+1
remaining=duration
local muted=Util.toHex(Theme.get("muted"))
local plain=tostring(cfg.Title or""):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
title.RichText=true
title.Text=plain..'  <font color="#'..muted..'">×'..entry.count.."</font>"
local scale=toast:FindFirstChildOfClass("UIScale")or create("UIScale",{Parent=toast})
scale.Scale=1.03
tween(scale,0.18,{Scale=1})
end
if not tracked or cfg.Duration then
timer=Util.Services.RunService.Heartbeat:Connect(function(dt)
if closed then return end
if hovered and cfg.PauseOnHover~=false then return end
remaining=remaining-(tonumber(dt)or 0)
if not tracked then progress.Size=UDim2.new(math.clamp(remaining/duration,0,1),0,0,2)end
if remaining<=0 then dismiss()end
end)
end
handle.Paused=function()return hovered end
function handle:GetCount()return entry.count end
entry.handle=setmetatable(handle,{
__index=function(_,key)
local value=toast[key]
if type(value)=="function"then return function(_,...)return value(toast,...)end end
return value
end,
})
return entry.handle
end
function Notify.pillHolder(Lib,bottom)
Lib._pillHolders=Lib._pillHolders or{}
local key=bottom and"Bottom"or"Top"
local existing=Lib._pillHolders[key]
if existing and existing.Parent then return existing end
local gui=Lib._pillGui
if not gui or not gui.Parent then
gui=Util.screenGui("QustahUI_Toasts",61)
Lib.maid:give(gui)
UIFont.register(gui,Lib.maid)
Lib._pillGui=gui
end
local holder=create("Frame",{
Name=key,BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,bottom and 1 or 0),
Position=UDim2.new(0.5,0,bottom and 1 or 0,bottom and-70 or 58),Size=UDim2.new(0,420,0,120),Parent=gui,
})
Util.list(holder,6,nil,Enum.HorizontalAlignment.Center,bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top)
Lib._pillHolders[key]=holder
return holder
end
function Notify.pill(Lib,cfg)
if type(cfg)~="table"then cfg={Text=tostring(cfg)}end
local bottom=cfg.Position=="Bottom"
local holder=Notify.pillHolder(Lib,bottom)
Lib._pillOrder=(Lib._pillOrder or 0)+1
local open={}
for _,child in ipairs(holder:GetChildren())do if child.Name=="Pill"and child:GetAttribute("Closing")~=true then open[#open+1]=child end end
table.sort(open,function(a,b)return a.LayoutOrder<b.LayoutOrder end)
while#open>=3 do
local old=table.remove(open,1)
old:SetAttribute("Closing",true)
tween(old,0.15,{GroupTransparency=1})
task.delay(0.16,function()if old.Parent then old:Destroy()end end)
end
local text=tostring(cfg.Text or cfg.Title or"")
local pill=create("CanvasGroup",{
Name="Pill",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,30),BorderSizePixel=0,
GroupTransparency=1,LayoutOrder=bottom and Lib._pillOrder or-Lib._pillOrder,Parent=holder,
})
Theme.bind(pill,"BackgroundColor3","card")
corner(pill,15)
local tint=(typeof(cfg.Color)=="Color3"or type(cfg.Color)=="string")and cfg.Color or"accent"
local edge=stroke(pill,nil,0.35)
Theme.bind(edge,"Color",cfg.Color and tint or"line")
local row=create("Frame",{Name="Row",BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromScale(0,1),Parent=pill})
Util.list(row,7,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
Util.padding(row,cfg.Image and 4 or 12,14,0,0)
if cfg.Image then
local image=create("ImageLabel",{Name="Image",BorderSizePixel=0,Size=UDim2.fromOffset(22,22),ScaleType=Enum.ScaleType.Crop,LayoutOrder=1,Image=tostring(cfg.Image),Parent=row})
Theme.bind(image,"BackgroundColor3","input")
corner(image,11)
elseif cfg.Icon and Icons.Get(cfg.Icon)then
Icons.themed(row,cfg.Icon,14,tint,{Name="Icon",LayoutOrder=1})
end
local caption=label(row,text,10,{Name="Text",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,30),Font=Enum.Font.GothamMedium,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2,RichText=true})
Theme.bind(caption,"TextColor3","heading")
create("UISizeConstraint",{MaxSize=Vector2.new(320,30),Parent=caption})
local scale=create("UIScale",{Scale=0.92,Parent=pill})
tween(pill,0.18,{GroupTransparency=0})
tween(scale,0.22,{Scale=1},Enum.EasingStyle.Back)
local closed=false
local function close()
if closed or not pill.Parent then return end
closed=true
pill:SetAttribute("Closing",true)
tween(pill,0.2,{GroupTransparency=1})
tween(scale,0.2,{Scale=0.94})
task.delay(0.22,function()if pill.Parent then pill:Destroy()end end)
end
task.delay(tonumber(cfg.Duration)or math.clamp(1.6+#text*0.04,2,6),close)
local handle={Frame=pill}
function handle:SetText(value)caption.Text=tostring(value)end
function handle:Close()close()end
return handle
end
return Notify
end
__modules["profiles"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local RED,GREEN,YELLOW="danger","success","warning"
return function(window,page,defaults)
local store=window.Config
store.DefaultFlags=defaults
local refresh,updateCurrent
local open
local query=""
local function meta()return store:ReadMeta()end
local function touch(name,fields)
local data=meta()
data[name]=data[name]or{}
for key,value in pairs(fields)do data[name][key]=value end
store:WriteMeta(data)
end
local function copy(text,what)
local clipboard=setclipboard or toclipboard
if type(clipboard)=="function"and pcall(clipboard,text)then
window:Notify({Title="Copied",Content=what.." copied to clipboard"})
return true
end
window:Notify({Title="Clipboard",Content="setclipboard is not available",Color=RED})
return false
end
local function say(text,bad)
window:Notify({
Title=bad==true and"Profiles · error"or"Profiles",Content=tostring(text),Duration=3,
Icon=bad==true and"triangle-alert"or(bad=="warn"and"info"or"circle-check"),
Color=bad==true and RED or(bad=="warn"and YELLOW or nil),
})
end
local function loadProfile(name,locked)
local function go()
if locked then
local failed=store:Apply(defaults)
store:_setActive(nil,nil)
say(failed>0 and(failed.." setting(s) could not be reset")or"Default settings restored",failed>0)
else
local ok,err=store:Load(name)
if ok then touch(name,{used=os.time()})end
say(ok and(err or("Loaded \""..name.."\""))or err,not ok)
end
refresh()
end
local changes=store:Changes()
if changes>0 then
window:Confirm("Load \""..name.."\"?",string.format("%d unsaved change%s in \"%s\" will be lost.",changes,changes==1 and""or"s",store.Active or"Default"),go,"Load")
else
go()
end
end
local function saveProfile(name)
local ok,err=store:Save(name)
if ok then touch(name,{saved=os.time(),used=os.time()})end
say(ok and("Saved \""..name.."\"")or err,not ok)
refresh()
return ok
end
local current=page:Card({Title="Current"})
local activeInfo=current:Info({Title="Profile",Value="Default"})
local changesInfo=current:Info({Title="Changes",Value="--"})
local bar=create("Frame",{Name="CurrentActions",BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),LayoutOrder=current:_order(),Parent=current.body})
Util.list(bar,6,Enum.FillDirection.Horizontal)
local ICONS={
Save="save",Revert="rotate-ccw",["Share current"]="share-2",["What changed?"]="list-checks",
Load="download",Overwrite="upload",Autoload="star",["Autoload off"]="star-off",Share="share-2",
Delete="trash-2",Rename="pencil",Duplicate="copy",
}
local function smallButton(parent,text,order,style)
local iconName=ICONS[text]
local button=create("TextButton",{
Name=text,Text=text,TextSize=9,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
Size=UDim2.fromOffset(Util.textWidth(text,9,Enum.Font.GothamMedium)+(iconName and 34 or 20),22),LayoutOrder=order,Parent=parent,
})
local icon=iconName and Icons.Image(iconName,{Name="ButtonIcon",Size=UDim2.fromOffset(11,11)})
if icon then
local content=create("Frame",{Name="Content",BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,Parent=button})
Util.list(content,5,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)
icon.LayoutOrder=1
icon.Parent=content
local text_=label(content,text,9,{Name="Label",Size=UDim2.fromScale(0,1),AutomaticSize=Enum.AutomaticSize.X,TextTruncate=Enum.TextTruncate.None,Font=Enum.Font.GothamMedium,LayoutOrder=2})
button.TextTransparency=1
local function tint()icon.ImageColor3=button.TextColor3 text_.TextColor3=button.TextColor3 end
button:GetPropertyChangedSignal("TextColor3"):Connect(tint)
task.defer(tint)
end
corner(button,6)
local outline=stroke(button)
if style=="Danger"then
Theme.bind(button,"BackgroundColor3","dangerDeep")
Theme.bind(button,"TextColor3","dangerText")
Theme.bind(outline,"Color","dangerEdge")
outline.Transparency=0.3
elseif style=="Primary"then
Theme.bind(button,"BackgroundColor3","accentDeep")
Theme.bind(button,"TextColor3","accent")
Theme.bind(outline,"Color","accent")
outline.Transparency=0.5
else
Theme.bind(button,"BackgroundColor3","input")
Theme.bind(button,"TextColor3","text")
Theme.bind(outline,"Color","buttonEdge")
end
button.MouseEnter:Connect(function()if style==nil then Theme.tweenTo(button,"BackgroundColor3","hover",0.1)end end)
button.MouseLeave:Connect(function()if style==nil then Theme.tweenTo(button,"BackgroundColor3","input",0.1)end end)
return button
end
local saveButton=smallButton(bar,"Save",1,"Primary")
saveButton.Activated:Connect(function()
if store.Active then saveProfile(store.Active)
else say("Default is locked - type a name under New profile and press Create","warn")end
end)
smallButton(bar,"Revert",2).Activated:Connect(function()
local changes=store:Changes()
if changes==0 then return say("Nothing to revert")end
window:Confirm("Revert "..changes.." change"..(changes==1 and""or"s").."?","Settings go back to \""..(store.Active or"Default").."\".",function()
local failed=store:Apply(store.ActiveFlags or defaults)
say(failed>0 and(failed.." setting(s) could not be reverted")or"Reverted",failed>0)
updateCurrent()
end,"Revert")
end)
smallButton(bar,"Share current",3).Activated:Connect(function()
local code=store:Export(nil)
if code then copy(code,"Share code")end
end)
smallButton(bar,"What changed?",4).Activated:Connect(function()
local count,names=store:Changes()
if count==0 then return say("No changes since \""..(store.Active or"Default").."\"")end
local titles={}
for _,flag in ipairs(names)do
local element=window.flags[flag]
titles[#titles+1]=element and element.Title and tostring(element.Title)or flag
end
table.sort(titles)
local shown={}
for index=1,math.min(#titles,12)do shown[index]=titles[index]end
window:Dialog({
Title=count.." change"..(count==1 and""or"s"),
Content=table.concat(shown,", ")..(#titles>12 and(" and "..(#titles-12).." more")or""),
Buttons={{Title="Close"}},
})
end)
function updateCurrent()
local name=store.Active
activeInfo:Set(name or"Default")
activeInfo:SetColor(name and"accent"or"text")
local changes=store:Changes()
if changes>0 then
changesInfo:Set(changes.." unsaved")
changesInfo:SetColor(YELLOW)
else
changesInfo:Set("Saved")
changesInfo:SetColor(GREEN)
end
end
local newCard=page:Card({Title="New profile"})
local sections=newCard:Tabs({"Create","Import"})
local function count(flags)local n=0 for _ in pairs(flags or{})do n=n+1 end return n end
sections.Create:ActionInput({
Name="CreateProfile",Icon="plus",Placeholder="Profile name",Button="Create",
Hint="Saves your current settings as a new profile",
Validate=function(name)
if name:lower()=="default"then return false,"\"Default\" is reserved"end
if name:gsub("[%w_%- ]","")~=""then return false,"Letters, numbers, spaces, - and _ only"end
if store:Exists(name)then return false,"\""..name.."\" already exists - open it and press Overwrite"end
return true,"Saves "..count(store:Snapshot()).." settings as \""..name.."\""
end,
Callback=function(name)
if saveProfile(name)then
open=name
say("Created \""..name.."\"")
refresh()
end
end,
})
sections.Import:ActionInput({
Name="ImportProfile",Icon="import",Placeholder="Paste a QUSTAH1: code",Button="Import",
Hint="Get a code with Share on any profile",
Validate=function(code)
local name,flags=store:Decode(code)
if not name then return false,flags end
local target=store:FreeName(name)
return true,"\""..name.."\" · "..count(flags).." settings"..(target~=name and(" → saved as \""..target.."\"")or"")
end,
Callback=function(code)
local name,flags,custom=store:Decode(code)
if not name then return say(flags,true)end
name=store:FreeName(name)
local ok,err=store:SaveFlags(name,flags,custom)
if not ok then return say(err,true)end
touch(name,{saved=os.time(),note="Imported"})
open=name
say("Imported as \""..name.."\" - open it and press Load")
refresh()
end,
})
newCard:Toggle({
Title="Separate profiles per game",Desc="Each game keeps its own list and autoload",Icon="gamepad-2",
Default=store.perGame~=nil,
Callback=function(on)
store:SetPerGame(on and"Game"or false)
window.memory.perGame=on and"Game"or false
window:_saveMemory()
open=nil
refresh()
say(on and("Profiles for this game (#"..game.GameId..")")or"Shared profiles for all games")
end,
})
local listCard=page:Card({Title="Saved"})
local search=create("TextBox",{
Name="Search",Text="",PlaceholderText="Search profiles...",TextSize=10,Font=Enum.Font.Gotham,
TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,
Size=UDim2.new(1,0,0,26),LayoutOrder=listCard:_order(),Parent=listCard.body,
})
Theme.bind(search,"BackgroundColor3","input")
Theme.bind(search,"TextColor3","text")
Theme.bind(search,"PlaceholderColor3","muted")
corner(search,6)
Theme.bind(stroke(search),"Color","buttonEdge")
Util.padding(search,9,9,0,0)
local holder=create("Frame",{Name="ProfileList",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=listCard:_order(),Parent=listCard.body})
Util.list(holder,4)
local empty=listCard:Label("")
local function profileRow(name,order,locked,autoload,info)
local active=(locked and store.Active==nil)or store.Active==name
local expanded=open==name
local frame=create("Frame",{Name="Profile_"..name,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,LayoutOrder=order,Parent=holder})
Theme.bind(frame,"BackgroundColor3",expanded and"selected"or"input")
corner(frame,6)
local outline=stroke(frame)
Theme.bind(outline,"Color",active and"accent"or(expanded and"buttonEdge"or"line"))
outline.Transparency=active and 0.55 or 0
Util.list(frame,0)
local note=info and info.note and tostring(info.note)or nil
local head=create("TextButton",{Name="Head",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,note and 42 or 34),LayoutOrder=1,Parent=frame})
local dot=create("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,12,0,17),Size=UDim2.fromOffset(6,6),BorderSizePixel=0,Parent=head})
Theme.bind(dot,"BackgroundColor3",active and"accent"or"buttonEdge")
corner(dot,3)
local title=label(head,name,11,{Name="Name",Position=UDim2.fromOffset(26,note and 6 or 0),Size=UDim2.new(0.55,-26,0,note and 18 or 34),Font=Enum.Font.GothamMedium})
Theme.bind(title,"TextColor3",(active or expanded)and"heading"or"text")
if note then
local noteLabel=label(head,note,9,{Name="Note",Position=UDim2.fromOffset(26,23),Size=UDim2.new(0.55,-26,0,13)})
Theme.bind(noteLabel,"TextColor3","muted")
end
local tags=create("Frame",{Name="Tags",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,0),Size=UDim2.new(0.45,-12,0,34),Parent=head})
Util.list(tags,6,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)
local function pill(text,order_,accent)
local object=label(tags,text,8,{
Name=text,Size=UDim2.fromOffset(Util.textWidth(text,8,Enum.Font.GothamMedium)+12,16),TextXAlignment=Enum.TextXAlignment.Center,
Font=Enum.Font.GothamMedium,BackgroundTransparency=0,LayoutOrder=order_,
})
corner(object,8)
Theme.bind(object,"BackgroundColor3",accent and"accentDeep"or"base")
Theme.bind(object,"TextColor3",accent and"accent"or"muted")
Theme.bind(stroke(object,nil,0.5),"Color",accent and"accent"or"buttonEdge")
end
if active then pill("ACTIVE",1,true)end
if autoload then pill("AUTO",2,false)end
if locked then pill("LOCKED",3,false)end
local when=info and(info.saved or info.used)
if when then
local date=label(tags,os.date("%d %b",when),9,{Size=UDim2.fromOffset(42,16),TextXAlignment=Enum.TextXAlignment.Right,LayoutOrder=4})
Theme.bind(date,"TextColor3","muted")
end
head.Activated:Connect(function()
open=open~=name and name or nil
refresh()
end)
if not expanded then return end
local actions=create("Frame",{Name="Actions",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2,Parent=frame})
Util.padding(actions,12,12,0,10)
Util.list(actions,6)
if not locked then
local flags=store:Read(name)
local differs=flags and store:Changes(flags)or 0
local summary=label(actions,flags and(differs==0 and"Same as your current settings"or(differs..(differs==1 and" setting differs"or" settings differ").." from your current settings"))or"File could not be read",9,{
Name="Summary",Size=UDim2.new(1,0,0,14),LayoutOrder=0,
})
Theme.bind(summary,"TextColor3","muted")
end
local function box(name_,placeholder,order_,width)
local object=create("TextBox",{
Name=name_,Text="",PlaceholderText=placeholder,TextSize=10,Font=Enum.Font.Gotham,
TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,Size=width,LayoutOrder=order_,
})
Theme.bind(object,"BackgroundColor3","base")
Theme.bind(object,"TextColor3","text")
Theme.bind(object,"PlaceholderColor3","muted")
corner(object,6)
Util.padding(object,8,8,0,0)
return object
end
if not locked then
local noteBox=box("Note","Add a note (e.g. ranked, low graphics)",1,UDim2.new(1,0,0,24))
noteBox.Text=note or""
noteBox.Parent=actions
noteBox.FocusLost:Connect(function()
local text=noteBox.Text:gsub("^%s+",""):gsub("%s+$",""):sub(1,60)
touch(name,{note=text~=""and text or false})
refresh()
end)
end
local nameRow=create("Frame",{Name="NameRow",BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),LayoutOrder=2,Parent=actions})
local nameBox=box("NewName",locked and"name for the copy"or"new name",1,UDim2.new(1,locked and-90 or-176,1,0))
nameBox.Parent=nameRow
local side=create("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(1,0),Size=UDim2.new(0,locked and 84 or 170,1,0),Parent=nameRow})
Util.list(side,6,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right)
local function typed()
local text=nameBox.Text:gsub("^%s+",""):gsub("%s+$","")
if text==""then say("Type a name in the box",true)return nil end
if text:lower()=="default"then say("\"Default\" is reserved",true)return nil end
return text
end
if not locked then
smallButton(side,"Rename",1).Activated:Connect(function()
local new=typed()
if not new then return end
local ok,err=store:Rename(name,new)
if ok then local m=meta()m[new],m[name]=m[name],nil store:WriteMeta(m)open=new end
say(ok and("Renamed to \""..new.."\"")or err,not ok)
refresh()
end)
end
smallButton(side,"Duplicate",2).Activated:Connect(function()
local new=typed()
if not new then return end
local ok,err
if store:Exists(new)then ok,err=false,"A profile with that name exists"
elseif locked then ok,err=store:SaveFlags(new,defaults)
else ok,err=store:Copy(name,new)end
if ok then touch(new,{saved=os.time(),note="Copy of "..name})open=new end
say(ok and("Copied to \""..new.."\"")or(err or"Copy failed"),not ok)
refresh()
end)
local buttons=create("Frame",{Name="Buttons",BackgroundTransparency=1,Size=UDim2.new(1,0,0,22),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=3,Parent=actions})
local flow=Util.list(buttons,6,Enum.FillDirection.Horizontal)
pcall(function()flow.Wraps=true end)
smallButton(buttons,"Load",1,"Primary").Activated:Connect(function()loadProfile(name,locked)end)
if not locked then
smallButton(buttons,"Overwrite",2).Activated:Connect(function()
window:Confirm("Overwrite \""..name.."\"?","It will hold your current settings.",function()saveProfile(name)end,"Overwrite")
end)
smallButton(buttons,autoload and"Autoload off"or"Autoload",3).Activated:Connect(function()
if autoload then store:ClearAutoLoad()say("Autoload off")
else store:SetAutoLoad(name)say("\""..name.."\" loads on start")end
refresh()
end)
end
smallButton(buttons,"Share",4).Activated:Connect(function()
local code=locked and("QUSTAH1:"..Util.base64encode(Util.Services.HttpService:JSONEncode({n="Default",f=defaults})))or store:Export(name)
if code then copy(code,"Share code for \""..name.."\"")end
end)
if not locked then
smallButton(buttons,"Delete",6,"Danger").Activated:Connect(function()
window:Confirm("Delete \""..name.."\"?","This cannot be undone.",function()
local ok,err=store:Delete(name)
if ok then
local m=meta()m[name]=nil store:WriteMeta(m)
if store:GetAutoLoad()==name then store:ClearAutoLoad()end
open=nil
end
say(ok and("Deleted \""..name.."\"")or err,not ok)
refresh()
end,"Delete",true)
end)
end
end
function refresh()
for _,child in ipairs(holder:GetChildren())do if child:IsA("GuiObject")then child:Destroy()end end
local auto=store:GetAutoLoad()
local data=meta()
local names={}
for _,name in ipairs(store:List())do if name:lower()~="default"then names[#names+1]=name end end
table.sort(names,function(a,b)
local ta=data[a]and(data[a].used or data[a].saved)or 0
local tb=data[b]and(data[b].used or data[b].saved)or 0
if ta~=tb then return ta>tb end
return a:lower()<b:lower()
end)
local q=query:lower()
local shown=0
if q==""or("default"):find(q,1,true)then profileRow("Default",1,true,auto==nil,nil)shown=shown+1 end
for index,name in ipairs(names)do
local info=data[name]
local note=info and info.note and tostring(info.note):lower()or""
if q==""or name:lower():find(q,1,true)or note:find(q,1,true)then
profileRow(name,index+1,false,auto==name,info)
shown=shown+1
end
end
search.Visible=#names>3 or q~=""
empty:Set(#names==0 and"No saved profiles yet - create one above."or(shown==0 and"No profile matches \""..query.."\""or""))
empty:SetVisible(#names==0 or shown==0)
updateCurrent()
end
search:GetPropertyChangedSignal("Text"):Connect(function()query=search.Text refresh()end)
store:OnActiveChanged(function()if page.frame.Visible then refresh()end end)
refresh()
page.frame:GetPropertyChangedSignal("Visible"):Connect(function()if page.frame.Visible then refresh()end end)
task.spawn(function()
while window.alive do
if window.visible and page.frame.Visible then updateCurrent()end
task.wait(1)
end
end)
return{refresh=refresh}
end
end
__modules["settings"]=function()
local Util=require("util")
local Theme=require("theme")
local Glow=require("glow")
local UIFont=require("font")
local Profiles=require("profiles")
local RED,GREEN="danger","success"
return function(window,cfg)
cfg=cfg or{}
local defaultSize=Vector2.new(window.width,window.height)
local tab=window:Tab({Title=cfg.Title or"Settings",Icon=cfg.Icon or"settings",Divider=cfg.Divider~=false,Header=cfg.Header~=false})
local interface=tab:Page("Interface")
local profiles=tab:Page("Profiles",{Columns=1})
local infoPage=tab:Page("Info")
local look=interface:Card({Title="Appearance",Side="Left"})
local picker
local swatches
local function syncSwatches()
if not swatches then return end
swatches:SetColor("Neutral",Theme.neutral(Theme.pack))
local accent=Theme.get("accentUser")
if accent==Theme.neutral(Theme.pack)then swatches:Set("Neutral",true)else swatches:Set(accent,true)end
end
local customThemes=window.Config:ReadJSON("themes")
for name,data in pairs(customThemes)do Theme.registerCustom(name,data)end
local themeDropdown=look:Dropdown({
Title="Theme",Options=Theme.packOrder,Default="Dark",Flag="__ui_theme",
Callback=function(name)
Theme.applyPack(name)
if picker then picker:Set(Theme.get("accentUser"),true)end
syncSwatches()
end,
})
swatches=look:Swatches({
Title="Accent",Default="Neutral",
Callback=function(color,name)
if name=="Neutral"then color=Theme.neutral(Theme.pack)end
if picker then picker:Set(color)end
end,
})
picker=look:ColorPicker({
Title="Custom accent",Desc="Any colour, saved with the profile",Flag="__ui_accent",Default=Theme.get("accentUser"),
Callback=function(color)Theme.set("accent",color)syncSwatches()end,
})
syncSwatches()
look:Dropdown({
Title="Font",Options=UIFont.order,Default="Gotham",Flag="__ui_font",
Callback=function(name)
if not UIFont.set(name)then window:Notify({Title="Font",Content=name.." is not available here",Color=RED})end
end,
})
look:Toggle({
Title="Text glow",Desc="Shine on the title and highlights",Flag="__ui_glow",Default=Glow.enabled,
Callback=function(on)Glow.setEnabled(on)end,
})
local menu=interface:Card({Title="Menu",Side="Right"})
local menuKey=menu:Keybind({
Title="Menu key",Desc="Opens and closes the menu",Flag="__ui_menu_key",Default=window.key,
Callback=function(key)window:SetToggleKey(key)end,
})
window._menuListeners=window._menuListeners or{}
table.insert(window._menuListeners,function(key)if menuKey.Value~=key then menuKey:Set(key,true)end end)
menu:Toggle({
Title="Welcome toast",Desc="Greets a new account on first open",
Default=window:_state("welcomeToast")~=false and window.cfg.Welcome~=false,
Callback=function(on)window:_state("welcomeToast",on)end,
})
local SCALES={"80%","90%","100%","110%","125%","150%"}
local current=math.floor((window:GetUIScale()*100)+0.5).."%"
menu:Dropdown({
Title="UI scale",Desc="Bigger or smaller menu",Options=SCALES,Default=table.find(SCALES,current)and current or"100%",
Callback=function(text)window:SetUIScale((tonumber(text:match("%d+"))or 100)/100)end,
})
local Sounds=require("sounds")
menu:Toggle({
Title="UI sounds",Desc="Soft clicks on buttons and switches",Flag="__ui_sounds",Default=Sounds.Enabled,
Callback=function(on)Sounds.Enabled=on end,
})
local Haptics=require("haptics")
menu:Toggle({Title="Haptics",Desc="Buzz on taps (phones)",Default=Haptics.Enabled,Callback=function(on)Haptics.Enabled=on end})
menu:Toggle({Title="Mobile button",Desc="Reopen button while hidden",Default=window.mobileButton==true,
Callback=function(on)window:SetMobileButton(on,true)end})
menu:Button({
Title="Reset window size / position",
Callback=function()
window.width,window.height,window.topLeft=defaultSize.X,defaultSize.Y,nil
window.memory.window=nil
window:_layout()
window:_saveMemory()
end,
})
menu:Button({
Title="Unload",
Callback=function()
window:Confirm("Unload "..window.Title.."?","The menu and everything it runs will be removed.",function()window:Destroy()end,"Unload",true)
end,
})
local editorCard=interface:Card({Title="Theme editor",Side="Right",Icon="paintbrush"})
local editor=editorCard:Section({Title="Edit colours",Opened=false})
local ROLE_NAMES={"Background","Cards","Inputs","Outlines","Text","Muted text","Headings","Dock","Icons","Accent"}
local ROLE_OF={}
for index,name in ipairs(ROLE_NAMES)do ROLE_OF[name]=Theme.EDITABLE[index]end
local roleColor
local roleDropdown=editor:Dropdown({Title="Colour",Options=ROLE_NAMES,Default="Background",
Callback=function(name)
local role=ROLE_OF[name]
if roleColor and role then roleColor:Set(Theme.get(role=="accent"and"accentUser"or role),true)end
end})
roleColor=editor:ColorPicker({Title="Value",Default=Theme.get("base"),
Callback=function(color)
local role=ROLE_OF[roleDropdown.Value or"Background"]
if not role then return end
if role=="accent"then picker:Set(color)else Theme.set(role,color)end
end})
local function saveThemes()window.Config:WriteJSON("themes",customThemes)end
local function refreshThemeList(select)
themeDropdown:SetOptions(Theme.packOrder,true)
if select then themeDropdown:Set(select)end
end
editor:ActionInput({Name="SaveTheme",Icon="save",Placeholder="Theme name",Button="Save",
Hint="Saves the colours above as a theme",
Validate=function(name)
if Theme.packs[name]and not Theme.packs[name].custom then return false,"\""..name.."\" is a built-in theme"end
return true,Theme.packs[name]and("Overwrites \""..name.."\"")or("Adds \""..name.."\" to the Theme list")
end,
Callback=function(name)
customThemes[name]=Theme.export()
Theme.registerCustom(name,customThemes[name])
saveThemes()
refreshThemeList(name)
window:Notify({Title="Theme saved",Content=name,Icon="palette"})
end})
local codeRow=editor:Row()
codeRow:Button({Title="Copy code",Icon="copy",Callback=function()
local code="QTHEME1:"..Util.base64encode(Util.Services.HttpService:JSONEncode({n=themeDropdown.Value or"Theme",t=Theme.export()}))
local clipboard=setclipboard or toclipboard
if clipboard and pcall(clipboard,code)then window:Notify({Title="Copied",Content="Theme code copied",Icon="palette"})end
end})
codeRow:Button({Title="Delete",Icon="trash-2",Risky=true,Callback=function()
local name=themeDropdown.Value
if not(name and Theme.packs[name]and Theme.packs[name].custom)then
return window:Notify({Title="Theme",Content="Only your own themes can be deleted",Color="warning"})
end
window:Confirm("Delete theme \""..name.."\"?","It is removed from this PC.",function()
customThemes[name]=nil
Theme.removeCustom(name)
saveThemes()
refreshThemeList("Dark")
end,"Delete",true)
end})
editor:ActionInput({Name="ImportTheme",Icon="import",Placeholder="Paste a theme code",Button="Import",
Validate=function(code)
local body=code:gsub("%s",""):match("^QTHEME1:(.+)$")
if not body then return false,"Not a theme code"end
local ok,data=pcall(function()return Util.Services.HttpService:JSONDecode(Util.base64decode(body))end)
if not ok or type(data)~="table"or type(data.t)~="table"then return false,"The code is damaged"end
return true,"Theme \""..tostring(data.n).."\""
end,
Callback=function(code)
local data=Util.Services.HttpService:JSONDecode(Util.base64decode(code:gsub("%s",""):match("^QTHEME1:(.+)$")))
local name=tostring(data.n or"Imported"):gsub("[^%w_%- ]","")
if Theme.packs[name]and not Theme.packs[name].custom then name=name.." (2)"end
customThemes[name]=data.t
if Theme.registerCustom(name,data.t)then
saveThemes()
refreshThemeList(name)
window:Notify({Title="Theme imported",Content=name,Icon="palette"})
end
end})
local look2=interface:Card({Title="Window",Side="Left"})
look2:Toggle({Title="Anonymous mode",Desc="Hides your name and avatar",Icon="venetian-mask",Flag="__ui_anon",Default=window.anonymous==true,
Callback=function(on)window:SetAnonymous(on)end})
if window.OnAnonymousChanged then
window:OnAnonymousChanged(function(on)local t=window.flags.__ui_anon if t and t.Value~=on then t:Set(on,true)end end)
end
look2:Slider({Title="Transparency",Flag="__ui_transparency",Min=0,Max=60,Default=0,Suffix="%",
Callback=function(value)window:SetBackgroundTransparency(value/100)end})
local bgAlpha
look2:Input({Title="Background",Placeholder="image id or url",Flag="__ui_bg",
Callback=function(text)window:SetBackgroundImage(text~=""and text or nil,bgAlpha and(1-bgAlpha.Value/100)or 0.85)end})
bgAlpha=look2:Slider({Title="Background visibility",Flag="__ui_bg_alpha",Min=0,Max=60,Default=15,Suffix="%",
Callback=function(value)if window._background then window._background.ImageTransparency=1-value/100 end end})
look2:Toggle({Title="Free mouse",Desc="Free cursor while open",Icon="hand",Flag="__ui_mouse",
Default=window.unlockMouse~=false,Callback=function(on)window:SetMouseUnlock(on)end})
look2:Toggle({Title="Animated background",Desc="Slow glow behind the menu",Icon="blend",Flag="__ui_live",
Default=window.liveBackground==true,Callback=function(on)window:SetLiveBackground(on)end})
look2:Toggle({Title="Edge glow",Desc="Pulsing accent border",Flag="__ui_edge_glow",
Default=window.accentGlow==true,Callback=function(on)window:SetAccentGlow(on)end})
look2:Toggle({Title="Blur game",Desc="Blurs the game while open",Flag="__ui_blur",
Default=window.blur==true,Callback=function(on)window:SetBlur(on)end})
look2:Button({Title="Fullscreen",Icon="maximize-2",Callback=function()window:ToggleFullscreen()end})
local overlays=interface:Card({Title="Overlays",Side="Right"})
overlays:Toggle({Title="Watermark",Desc="Name · FPS · ping · clock",Flag="__ui_hud_watermark",Callback=function(on)window:Watermark(on)end})
overlays:Toggle({Title="Keybind list",Desc="Bound keys on screen",Flag="__ui_hud_keys",Callback=function(on)window:KeybindList(on)end})
overlays:Toggle({Title="Session bar",Desc="FPS · ping · players · time",Flag="__ui_hud_session",Callback=function(on)window:SessionBar(on)end})
overlays:Dropdown({
Title="Performance",Options={"Off","Header","Floating"},Default="Off",Flag="__ui_hud_stats",
Callback=function(mode)window:StatsMonitor(mode)end,
})
Profiles(window,profiles,window.Config.Defaults)
local about=infoPage:Card({Title="About",Side="Left"})
if window.Version~=""then about:Info({Title=window.Title,Value=window.Version})end
about:Info({Title="qustah-ui-lib",Value="v"..tostring(window.Lib.Version)})
for _,entry in ipairs(cfg.Info or{})do about:Info({Title=entry[1],Value=entry[2],Copy=entry.Copy})end
local files=type(writefile)=="function"and type(readfile)=="function"
about:Info({Title="File access",Value=files and"Yes"or"No (profiles off)"})
if type(window.cfg.Changelog)=="table"then
about:Button({Title="What's new",Icon="newspaper",Callback=function()window:ShowChangelog()end})
end
if window.cfg.Tour then
about:Button({Title="Show the tour",Icon="map",Callback=function()
local spec=window.cfg.Tour
window:Tour(type(spec)=="table"and spec or nil,{Id=window.cfg.TourId,Force=true})
end})
end
about:Info({Title="Secure mode",Value=Util.secure and"On"or"Off",Help="Random gui names and a silent console. Turn it on with getgenv().QUSTAH_SECURE = true before loading, or CreateWindow({ Secure = true })"})
if window.GetKicks and window.cfg.KickLog~=false then
local kicksCard=infoPage:Card({Title="Disconnects",Side="Left",Icon="log-out",Desc="Kicks and drops, with Roblox's reason"})
local kickText=kicksCard:Paragraph({Content="None yet"})
local function showKicks()
local list=window:GetKicks()
local lines={}
for index,entry in ipairs(list)do
if index>5 then break end
lines[#lines+1]=string.format("<font color=\"#%s\">%s</font>  %s  <font color=\"#%s\">%s</font>",
Util.toHex(Theme.get((entry.Code==277 or entry.Code==279)and"warning"or"danger")),tostring(entry.Kind or"Kicked"),
(tostring(entry.Reason or""):gsub("<","&lt;")),Util.toHex(Theme.get("muted")),Util.ago(entry.Time))
end
kickText:Set(#lines>0 and table.concat(lines,"\n")or"None yet")
end
kicksCard:Button({Title="Clear",Icon="trash-2",Callback=function()
window.Config:WriteJSON("kicks",{list={}})
showKicks()
end})
window:OnKick(showKicks)
Theme.onChange(function()if infoPage.frame.Parent then showKicks()end end)
showKicks()
end
local modulesCard=infoPage:Card({Title="Modules",Side="Left"})
local moduleRows={}
local noModules=modulesCard:Label("No modules reported")
local errorsCard=infoPage:Card({Title="Errors",Side="Right"})
errorsCard:Toggle({
Title="Debug mode",Desc="A notification for every new error",Flag="__ui_debug",Default=window.cfg.Debug==true,
Callback=function(on)window.debug=on end,
})
local errorCount=errorsCard:Info({Title="Errors",Value="0"})
local errorText=errorsCard:Paragraph({Content="No errors"})
errorsCard:Button({
Title="Copy report",
Callback=function()
local clipboard=setclipboard or toclipboard
if type(clipboard)=="function"and pcall(clipboard,window:GetErrorReport())then
window:Notify({Title="Copied",Content="Error report copied to clipboard"})
else
window:Notify({Title="Clipboard",Content="setclipboard is not available",Color=RED})
end
end,
})
errorsCard:Button({Title="Clear",Callback=function()window:ClearErrors()end})
local STATE={On=GREEN,Off=nil,Limited="warning",Error=RED}
local function update()
local order,modules=window:GetModules()
noModules:SetVisible(#order==0)
for _,name in ipairs(order)do
local row=moduleRows[name]or modulesCard:Info({Title=name})
moduleRows[name]=row
local module=modules[name]
row:Set(module.state..(module.detail and module.state~="Error"and(" · "..tostring(module.detail))or""))
row:SetColor(STATE[module.state]or"muted")
end
local errors=window:GetErrors()
local total=0
local lines={}
for index,entry in ipairs(errors)do
total=total+entry.count
if index<=8 then
lines[#lines+1]=string.format("<font color=\"#%s\">%s</font>%s  %s",Util.toHex(Theme.get("danger")),entry.source,entry.count>1 and(" ×"..entry.count)or"",(tostring(entry.message):gsub("<","&lt;")))
end
end
if#errors>8 then lines[#lines+1]="+"..(#errors-8).." more (Copy report)"end
errorCount:Set(#errors==0 and"0"or(#errors..(total>#errors and(" ("..total.."×)")or"")))
errorCount:SetColor(#errors>0 and RED or"text")
errorText:Set(#lines>0 and table.concat(lines,"\n")or"No errors")
end
window:OnStatusChanged(update)
Theme.onChange(function()if infoPage.frame.Parent then update()end end)
update()
window.settingsTab=tab
return tab
end
end
__modules["sounds"]=function()
local Util=require("util")
local PING="rbxasset://sounds/electronicpingshort.wav"
local Sounds={
Enabled=false,
Volume=0.35,
Map={
click={PING,2.2,0.35},
toggle={PING,1.8,0.4},
tab={PING,2.6,0.25},
error={PING,0.7,0.5},
},
}
local Haptics=require("haptics")
local last={}
function Sounds.Play(name)
Haptics.Play(name=="error"and"notify"or"click")
if not Sounds.Enabled then return end
local entry=Sounds.Map[name]
if not entry then return end
local now=os.clock()
if last[name]and now-last[name]<0.06 then return end
last[name]=now
pcall(function()
local sound=Instance.new("Sound")
sound.SoundId=entry[1]
sound.PlaybackSpeed=entry[2]or 1
sound.Volume=math.clamp((tonumber(Sounds.Volume)or 0.35)*(entry[3]or 1),0,1)
sound.Parent=Util.Services.SoundService
sound:Play()
task.delay(2,function()sound:Destroy()end)
end)
end
function Sounds.Set(name,id,speed,volume)
local value=tostring(id or"")
if value:match("^%d+$")then value="rbxassetid://"..value end
Sounds.Map[name]={value,tonumber(speed)or 1,tonumber(volume)or 1}
end
return Sounds
end
__modules["stats"]=function()
local Util=require("util")
local Services=Util.Services
local Stats={fps=0,ping=0,history={fps={},ping={}},running=false}
local listeners={}
local HISTORY=60
function Stats.start(maid)
if Stats.running then return end
Stats.running=true
local frames,last=0,os.clock()
maid:connect(Services.RunService.RenderStepped,function()frames=frames+1 end)
task.spawn(function()
while Stats.running do
task.wait(0.5)
local now=os.clock()
Stats.fps=math.floor(frames/math.max(now-last,1e-3)+0.5)
frames,last=0,now
local ok,ping=pcall(function()return Services.Players.LocalPlayer:GetNetworkPing()*1000 end)
Stats.ping=ok and math.floor(ping+0.5)or Stats.ping
for key,value in pairs({fps=Stats.fps,ping=Stats.ping})do
local list=Stats.history[key]
list[#list+1]=value
if#list>HISTORY then table.remove(list,1)end
end
for _,listener in ipairs(listeners)do Util.safe(listener,Stats)end
end
end)
maid:give(function()Stats.running=false end)
end
function Stats.listen(callback)
listeners[#listeners+1]=callback
return function()
local index=table.find(listeners,callback)
if index then table.remove(listeners,index)end
end
end
return Stats
end
__modules["status"]=function()
local Util=require("util")
local Theme=require("theme")
local GREEN,YELLOW,RED="success","warning","danger"
return function(Window)
local function changed(self)
self:_refreshStatus()
for _,listener in ipairs(self._statusListeners or{})do Util.safe(listener,self)end
end
function Window:OnStatusChanged(callback)
self._statusListeners=self._statusListeners or{}
table.insert(self._statusListeners,callback)
end
function Window:SetModule(name,state,detail)
name=tostring(name)
self.modules=self.modules or{}
self.moduleOrder=self.moduleOrder or{}
if not self.modules[name]then table.insert(self.moduleOrder,name)end
self.modules[name]={state=tostring(state or"Off"),detail=detail}
if state=="Error"then self:ReportError(name,detail or"Module stopped with an error")return end
changed(self)
end
function Window:GetModules()return self.moduleOrder or{},self.modules or{}end
function Window:ReportError(source,message)
source,message=tostring(source or"Script"),tostring(message or"Unknown error")
self.errors=self.errors or{}
self._errorIndex=self._errorIndex or{}
local key=source.."\0"..message
local entry=self._errorIndex[key]
if entry then
entry.count=entry.count+1
entry.last=os.time()
else
entry={source=source,message=message,count=1,first=os.time(),last=os.time()}
self._errorIndex[key]=entry
table.insert(self.errors,entry)
Util.log(string.format("[%s / %s] %s",self.Title,source,message))
if self.debug==nil then self.debug=self.cfg.Debug==true end
if self.debug and self.Notify then
local short=message:gsub("^.-:%d+: ","")
self:Notify({
Title="Error · "..source,Content=short,Icon="triangle-alert",Color=RED,Duration=6,
Buttons={{Title="Copy",Callback=function()
local clipboard=setclipboard or toclipboard
if clipboard then pcall(clipboard,source..": "..message)end
end}},
})
end
end
changed(self)
end
function Window:GetErrors()return self.errors or{}end
function Window:ClearErrors()
self.errors,self._errorIndex={},{}
for _,module in pairs(self.modules or{})do if module.state=="Error"then module.state="Off"end end
changed(self)
end
function Window:GetErrorReport()
local lines={string.format("%s %s - error report (%s)",self.Title,self.Version,os.date("%Y-%m-%d %H:%M"))}
for _,name in ipairs(self.moduleOrder or{})do
local module=self.modules[name]
lines[#lines+1]=string.format("module %s: %s%s",name,module.state,module.detail and(" ("..tostring(module.detail)..")")or"")
end
for _,entry in ipairs(self.errors or{})do
lines[#lines+1]=string.format("x%d %s: %s",entry.count,entry.source,entry.message)
end
if#(self.errors or{})==0 then lines[#lines+1]="no errors"end
return table.concat(lines,"\n")
end
function Window:SetStatus(text,color)
self._manualStatus=text~=nil and{text=tostring(text),color=color}or nil
self:_refreshStatus()
end
function Window:_refreshStatus()
if not self.statusLabel then return end
local text,color
local errorCount=#(self.errors or{})
local limited=false
for _,module in pairs(self.modules or{})do if module.state=="Limited"then limited=true end end
if self._manualStatus then
text,color=self._manualStatus.text,self._manualStatus.color
elseif errorCount>0 then
text,color="Errors: "..errorCount,RED
elseif limited then
text,color="Limited",YELLOW
else
text,color="Connected",GREEN
end
self.statusText=text
self.statusLabel.Text=text
if color~=nil and self.statusDot then Theme.bind(self.statusDot,"ImageColor3",color)end
end
function Window:_safe(source,callback,...)
if type(callback)~="function"then return nil end
local ok,err=pcall(callback,...)
if not ok then self:ReportError(source,err)end
return ok
end
end
end
__modules["theme"]=function()
local Util=require("util")
local Theme={}
local rgb=Color3.fromRGB
Theme.colors={
base=rgb(15,15,16),
footer=rgb(12,12,13),
dock=rgb(16,16,16),
selected=rgb(33,33,36),
icon=rgb(192,192,192),
card=rgb(19,19,20),
input=rgb(25,25,27),
hover=rgb(33,33,36),
line=rgb(36,36,39),
edge=rgb(30,30,30),
buttonEdge=rgb(46,46,50),
text=rgb(168,168,172),
muted=rgb(118,118,124),
heading=rgb(205,205,210),
knob=rgb(190,190,195),
accent=rgb(177,178,183),
success=rgb(110,200,130),
warning=rgb(215,180,120),
danger=rgb(215,130,130),
dangerDeep=rgb(70,32,36),
dangerEdge=rgb(150,60,66),
dangerText=rgb(235,150,155),
codeKeyword=rgb(199,146,234),codeString=rgb(195,232,141),codeNumber=rgb(247,140,108),
codeComment=rgb(107,112,128),codeGlobal=rgb(130,170,255),codeCall=rgb(255,203,107),
}
Theme.colors.accentUser=Theme.colors.accent
local function luminance(c)
local function channel(v)return v<=0.03928 and v/12.92 or((v+0.055)/1.055)^2.4 end
return 0.2126*channel(c.R)+0.7152*channel(c.G)+0.0722*channel(c.B)
end
local function contrast(a,b)
local la,lb=luminance(a),luminance(b)
return(math.max(la,lb)+0.05)/(math.min(la,lb)+0.05)
end
Theme.contrast=contrast
local function derive()
local colors=Theme.colors
local accent=colors.accentUser or colors.accent
local light=luminance(colors.base)>0.5
if light then
local black=Color3.new(0,0,0)
for _=1,16 do
local deep=colors.base:Lerp(accent,0.12)
if contrast(accent,colors.card)>=3 and contrast(accent,deep)>=3 and contrast(accent,colors.dock or colors.base)>=3 then break end
accent=accent:Lerp(black,0.08)
end
end
colors.accent=accent
Theme.isLight=light
colors.accentDeep=colors.base:Lerp(colors.accent,0.12)
if colors.muted and colors.input and colors.text then
for _=1,10 do
if contrast(colors.muted,colors.input)>=3 then break end
colors.muted=colors.muted:Lerp(colors.text,0.12)
end
end
colors.toggleOn=colors.input:Lerp(colors.accent,Theme.isLight and 0.85 or 0.42)
colors.accentEdge=colors.base:Lerp(colors.accent,0.35)
local white=Color3.new(1,1,1)
colors.onAccent=contrast(colors.base,colors.accent)>contrast(white,colors.accent)and colors.base or white
end
derive()
local bound={}
local function track(object)
local entry={}
bound[object]=entry
pcall(function()
local connection
connection=object.Destroying:Connect(function()
bound[object]=nil
if connection then connection:Disconnect()end
end)
end)
return entry
end
function Theme._binding(object)return bound[object]end
function Theme._boundCount()
local count=0
for _ in pairs(bound)do count=count+1 end
return count
end
local listeners={}
function Theme.get(role)
return Theme.colors[role]or role
end
function Theme.bind(object,property,role)
local entry=bound[object]or track(object)
entry[property]=role
object[property]=Theme.get(role)
return object
end
function Theme.tweenTo(object,property,role,duration)
local entry=bound[object]or track(object)
entry[property]=role
if duration and duration>0 then
Util.tween(object,duration,{[property]=Theme.get(role)})
else
object[property]=Theme.get(role)
end
end
function Theme.set(role,color)
if typeof(color)~="Color3"then return end
if role=="accent"then role="accentUser"end
Theme.colors[role]=color
if role=="accentUser"or role=="base"or role=="input"or role=="card"then derive()end
for object,properties in pairs(bound)do
if object.Parent then
for property,boundRole in pairs(properties)do
pcall(function()object[property]=Theme.get(boundRole)end)
end
end
end
for _,listener in ipairs(listeners)do Util.safe(listener,role,color)end
end
function Theme.setMany(colors)
for role,color in pairs(colors)do
if typeof(color)=="Color3"then Theme.colors[role=="accent"and"accentUser"or role]=color end
end
derive()
for object,properties in pairs(bound)do
if object.Parent then
for property,boundRole in pairs(properties)do
pcall(function()object[property]=Theme.get(boundRole)end)
end
end
end
for _,listener in ipairs(listeners)do Util.safe(listener,"*",nil)end
end
Theme.packs={
Dark={},
Midnight={
base=rgb(12,14,22),footer=rgb(9,11,18),dock=rgb(13,15,24),selected=rgb(30,34,50),icon=rgb(180,188,210),
card=rgb(16,19,29),input=rgb(22,26,39),hover=rgb(30,35,52),line=rgb(33,38,55),edge=rgb(28,32,46),
buttonEdge=rgb(45,51,72),text=rgb(165,172,192),muted=rgb(110,118,140),heading=rgb(208,214,232),knob=rgb(196,202,220),
},
AMOLED={
base=rgb(0,0,0),footer=rgb(0,0,0),dock=rgb(0,0,0),selected=rgb(26,26,28),icon=rgb(190,190,190),
card=rgb(8,8,9),input=rgb(16,16,18),hover=rgb(26,26,28),line=rgb(30,30,33),edge=rgb(28,28,28),
buttonEdge=rgb(42,42,46),text=rgb(170,170,174),muted=rgb(115,115,120),heading=rgb(215,215,220),knob=rgb(195,195,200),
},
Light={
base=rgb(238,238,241),footer=rgb(229,229,233),dock=rgb(234,234,238),selected=rgb(216,216,222),icon=rgb(85,85,95),
card=rgb(247,247,249),input=rgb(231,231,235),hover=rgb(221,221,226),line=rgb(214,214,220),edge=rgb(200,200,206),
buttonEdge=rgb(190,190,198),text=rgb(62,62,70),muted=rgb(120,120,130),heading=rgb(25,25,30),knob=rgb(255,255,255),
success=rgb(30,135,70),warning=rgb(165,105,15),danger=rgb(190,55,55),
dangerDeep=rgb(252,230,230),dangerEdge=rgb(225,150,150),dangerText=rgb(170,40,40),
codeKeyword=rgb(135,55,195),codeString=rgb(35,125,55),codeNumber=rgb(195,85,35),
codeComment=rgb(135,135,145),codeGlobal=rgb(35,95,200),codeCall=rgb(150,100,0),
},
}
local hex=function(text)return Color3.fromRGB(tonumber(text:sub(2,3),16),tonumber(text:sub(4,5),16),tonumber(text:sub(6,7),16))end
Theme.hex=hex
function Theme.makePack(p)
local base,text=hex(p.base),hex(p.text)
local function step(t)return base:Lerp(text,t)end
local pack={
base=base,footer=base:Lerp(Color3.new(0,0,0),0.18),dock=p.dock and hex(p.dock)or base,
card=p.card and hex(p.card)or step(0.026),input=p.input and hex(p.input)or step(0.065),
selected=step(0.118),hover=step(0.118),line=step(0.137),edge=step(0.098),buttonEdge=step(0.203),
text=text,muted=hex(p.muted),heading=hex(p.heading or p.text),icon=text:Lerp(hex(p.heading or p.text),0.5),
knob=text:Lerp(Color3.new(1,1,1),0.15),accent=p.accent and hex(p.accent)or nil,
}
for _=1,10 do if contrast(pack.text,pack.card)>=4.5 then break end pack.text=pack.text:Lerp(pack.heading,0.2)end
for _=1,10 do if contrast(pack.muted,pack.card)>=3 then break end pack.muted=pack.muted:Lerp(pack.text,0.15)end
for _=1,10 do if contrast(pack.buttonEdge,pack.card)>=1.35 then break end pack.buttonEdge=pack.buttonEdge:Lerp(text,0.08)end
return pack
end
local PALETTES={
{"Tokyo Night",{base="#1a1b26",card="#1f2131",input="#272a3d",text="#a9b1d6",muted="#6a7299",heading="#c0caf5",accent="#7aa2f7"}},
{"Catppuccin",{base="#1e1e2e",card="#232334",input="#2b2b3e",text="#bac2de",muted="#7f849c",heading="#cdd6f4",accent="#cba6f7"}},
{"Dracula",{base="#21222c",card="#282a36",input="#30323f",text="#d6d6d0",muted="#7484b8",heading="#f8f8f2",accent="#bd93f9"}},
{"Nord",{base="#2e3440",card="#343b49",input="#3b4252",text="#d8dee9",muted="#8892a6",heading="#eceff4",accent="#88c0d0"}},
{"Gruvbox",{base="#1d2021",card="#252525",input="#2e2c2b",text="#d5c4a1",muted="#928374",heading="#fbf1c7",accent="#fabd2f"}},
{"One Dark",{base="#21252b",card="#282c34",input="#2f343e",text="#abb2bf",muted="#727a87",heading="#d7dae0",accent="#61afef"}},
{"Monokai",{base="#1e1f1c",card="#272822",input="#30312a",text="#d6d6cf",muted="#8a8571",heading="#f8f8f2",accent="#a6e22e"}},
{"Rose Pine",{base="#191724",card="#1f1d2e",input="#26233a",text="#d2cfea",muted="#7f7a99",heading="#e0def4",accent="#c4a7e7"}},
{"Everforest",{base="#272e33",card="#2d353b",input="#343f44",text="#d3c6aa",muted="#859289",heading="#e6dcc0",accent="#a7c080"}},
{"Kanagawa",{base="#1a1a22",card="#1f1f28",input="#2a2a37",text="#dcd7ba",muted="#7a7970",heading="#f2ecbc",accent="#7e9cd8"}},
{"Solarized",{base="#00212b",card="#002b36",input="#073642",text="#93a1a1",muted="#657b83",heading="#eee8d5",accent="#268bd2"}},
{"Oceanic",{base="#17252d",card="#1b2b34",input="#22343e",text="#c0c5ce",muted="#6f7d88",heading="#d8dee9",accent="#6699cc"}},
{"Fatality",{base="#140f2b",card="#1a1436",input="#221a44",text="#c9c2e6",muted="#7f76a6",heading="#efeaff",accent="#f0024f"}},
{"Mint",{base="#141615",card="#191c1a",input="#202422",text="#c2ccc6",muted="#7c8781",heading="#e3ebe6",accent="#3db488"}},
{"Cyberpunk",{base="#0d0a17",card="#130f21",input="#1b152d",text="#c9c1e8",muted="#7d74a0",heading="#f0e9ff",accent="#f72585"}},
}
for _,entry in ipairs(PALETTES)do Theme.packs[entry[1]]=Theme.makePack(entry[2])end
Theme.packs.Latte={
base=rgb(230,233,239),footer=rgb(220,224,232),dock=rgb(230,233,239),selected=rgb(204,208,218),icon=rgb(76,79,105),
card=rgb(239,241,245),input=rgb(220,224,232),hover=rgb(210,214,224),line=rgb(204,208,218),edge=rgb(188,192,204),
buttonEdge=rgb(172,176,190),text=rgb(76,79,105),muted=rgb(124,127,147),heading=rgb(48,52,70),knob=rgb(255,255,255),
accent=rgb(136,57,239),
success=rgb(40,130,40),warning=rgb(170,100,10),danger=rgb(200,40,70),
dangerDeep=rgb(250,225,230),dangerEdge=rgb(230,150,165),dangerText=rgb(180,30,60),
codeKeyword=rgb(136,57,239),codeString=rgb(64,160,43),codeNumber=rgb(254,100,11),
codeComment=rgb(140,143,161),codeGlobal=rgb(30,102,245),codeCall=rgb(223,142,29),
}
Theme.packOrder={"Dark","Midnight","AMOLED","Light","Latte"}
for _,entry in ipairs(PALETTES)do table.insert(Theme.packOrder,entry[1])end
local DEFAULTS={}
for role,color in pairs(Theme.colors)do DEFAULTS[role]=color end
Theme.defaults=DEFAULTS
function Theme.neutral(pack)
local data=Theme.packs[pack]
if data and data.accent then return data.accent end
return pack=="Light"and rgb(70,70,80)or rgb(177,178,183)
end
function Theme.applyPack(name)
local pack=Theme.packs[name]
if not pack then return false end
local colors={}
for role,color in pairs(DEFAULTS)do if role~="accent"and role~="accentUser"then colors[role]=color end end
for role,color in pairs(pack)do if role~="accent"then colors[role]=color end end
local accent=Theme.colors.accentUser
if accent==Theme.neutral(Theme.pack)or accent==Theme.neutral("Dark")or accent==Theme.neutral("Light")then colors.accentUser=Theme.neutral(name)end
Theme.pack=name
Theme.setMany(colors)
return true
end
Theme.pack="Dark"
Theme.EDITABLE={"base","card","input","line","text","muted","heading","dock","icon","accent"}
function Theme.export()
local data={}
for _,role in ipairs(Theme.EDITABLE)do
local color=Theme.colors[role=="accent"and"accentUser"or role]
data[role]="#"..Util.toHex(color)
end
return data
end
function Theme.registerCustom(name,data)
if type(data)~="table"or type(data.base)~="string"or type(data.text)~="string"then return false end
local ok,pack=pcall(function()
local made=Theme.makePack({
base=data.base,card=data.card,input=data.input,text=data.text,muted=data.muted or data.text,
heading=data.heading,accent=data.accent,dock=data.dock,
})
if data.line then made.line=hex(data.line)end
if data.icon then made.icon=hex(data.icon)end
if luminance(made.base)>0.5 then
for role,color in pairs(Theme.packs.Light)do if made[role]==nil or role:match("^code")or role:match("^danger")or role=="success"or role=="warning"then made[role]=made[role]or color end end
for _,role in ipairs({"success","warning","danger","dangerDeep","dangerEdge","dangerText","codeKeyword","codeString","codeNumber","codeComment","codeGlobal","codeCall"})do made[role]=Theme.packs.Light[role]end
end
made.custom=true
return made
end)
if not ok then return false end
Theme.packs[name]=pack
if not table.find(Theme.packOrder,name)then table.insert(Theme.packOrder,name)end
return true
end
function Theme.removeCustom(name)
if not(Theme.packs[name]and Theme.packs[name].custom)then return false end
Theme.packs[name]=nil
local index=table.find(Theme.packOrder,name)
if index then table.remove(Theme.packOrder,index)end
return true
end
function Theme.onChange(callback)
listeners[#listeners+1]=callback
end
return Theme
end
__modules["tour"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke,label=Util.create,Util.corner,Util.stroke,Util.label
local PANEL=236
local PAD=6
return function(Window)
local function guiOf(window,target)
if typeof(target)=="Instance"then return target end
if type(target)=="string"then
local name=target:lower()
if name=="dock"then return window.dock end
if name=="header"then return window.main and window.main:FindFirstChild("Header")end
if name=="footer"then return window.footer end
if name=="status"then return window.statusLabel end
if name=="menukey"then return window.menuHint and window.menuHint.Row end
if name=="settings"then return window.settingsTab and window.settingsTab.button end
if name=="bell"then return window.main and window.main:FindFirstChild("Bell",true)end
if name=="close"then return window.main and window.main:FindFirstChild("Close",true)end
return nil
end
if type(target)=="table"then
if target.button and target.Pages then return target.button end
if target.Row then return target.Row end
if target.frame then return target.frame end
end
return nil
end
local function reveal(window,target)
local card=type(target)=="table"and(target.Card or(target.frame and target.page and target))or nil
local page=card and card.page
if page and page.tab then
if window.current~=page.tab then pcall(page.tab.Select,page.tab)end
if page.tab.current~=page then pcall(page.Select,page)end
end
if type(target)=="table"and target.button and target.Pages and window.current~=target then pcall(target.Select,target)end
local object=guiOf(window,target)
if not object then return end
local scroller=object:FindFirstAncestorWhichIsA("ScrollingFrame")
if scroller then
local top=object.AbsolutePosition.Y-scroller.AbsolutePosition.Y
local bottom=top+object.AbsoluteSize.Y
if top<0 or bottom>scroller.AbsoluteSize.Y then
local y=math.max(0,scroller.CanvasPosition.Y+top-24)
scroller.CanvasPosition=Vector2.new(scroller.CanvasPosition.X,y)
end
end
end
function Window:_defaultTourSteps()
local key=Util.keyName(self.key):upper()
local steps={
{Target="dock",Title="Tabs",Text="Every part of the script has its own tab here. Hover an icon to see its name."},
{Target="header",Title="Move and resize",Text="Drag the header to move the window, drag the bottom-right corner to resize it. Double-click the header for fullscreen."},
{Target="menuKey",Title="Menu key",Text="Press "..key.." to hide or show the menu. Click the key to change it."},
{Target="settings",Title="Settings",Text="Themes, fonts, profiles and overlays live here. Profiles save every setting so you can load them next time."},
{Target="status",Title="Status",Text="Green means everything works. If a feature fails, it turns red and Settings > Info says why."},
}
local out={}
for _,step in ipairs(steps)do if guiOf(self,step.Target)then out[#out+1]=step end end
return out
end
function Window:ResetTour(id)self:_state("tour:"..tostring(id or"default"),false)end
function Window:HasSeenTour(id)return self:_state("tour:"..tostring(id or"default"))==true end
function Window:_autoTour()
local spec=self.cfg.Tour
if not spec or self:HasSeenTour(self.cfg.TourId)then return end
task.delay(tonumber(self.cfg.TourDelay)or 2.5,function()
for _=1,40 do
if not self.alive then return end
if not self._dialog and self.visible then break end
task.wait(0.5)
end
if self.alive then self:Tour(type(spec)=="table"and spec or nil,{Once=true,Id=self.cfg.TourId})end
end)
end
function Window:Tour(steps,opts)
opts=opts or{}
if type(steps)~="table"or#steps==0 then steps=self:_defaultTourSteps()end
local id=tostring(opts.Id or"default")
if opts.Once and not opts.Force and self:HasSeenTour(id)then return nil end
if#steps==0 or not self.alive then return nil end
if self._tour then self._tour:Close(false)end
if not self.visible then self:SetVisible(true)end
self:_closePopup()
local window=self
local tour={Index=0,Steps=steps}
local alive=true
local scale=self.scale and self.scale.Scale or 1
local overlay=create("Frame",{Name="Tour",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=300,Parent=self.gui})
local panes={}
for index=1,4 do
local pane=create("TextButton",{Name="Dim"..index,Text="",AutoButtonColor=false,BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.45,ZIndex=300,Parent=overlay})
panes[index]=pane
end
local ring=create("Frame",{Name="Ring",BackgroundTransparency=1,BorderSizePixel=0,ZIndex=301,Parent=overlay})
corner(ring,9)
local ringStroke=stroke(ring,nil,0,2)
Theme.bind(ringStroke,"Color","accent")
local glow=create("Frame",{Name="Glow",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(-4,-4),Size=UDim2.new(1,8,1,8),ZIndex=301,Parent=ring})
corner(glow,12)
local glowStroke=stroke(glow,nil,0.7,4)
Theme.bind(glowStroke,"Color","accent")
local panel=create("Frame",{Name="Panel",BorderSizePixel=0,Size=UDim2.fromOffset(PANEL,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=302,Parent=overlay})
create("UIScale",{Scale=scale,Parent=panel})
Theme.bind(panel,"BackgroundColor3","card")
corner(panel,10)
Theme.bind(stroke(panel),"Color","buttonEdge")
Util.padding(panel,14,14,12,12)
Util.list(panel,6)
local head=create("Frame",{Name="Head",BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),LayoutOrder=1,ZIndex=302,Parent=panel})
local titleLabel=label(head,"",11,{Name="Title",Size=UDim2.new(1,-24,1,0),Font=Enum.Font.GothamMedium,ZIndex=303})
Theme.bind(titleLabel,"TextColor3","heading")
local skip=create("TextButton",{Name="Skip",Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,4,0.5,0),Size=UDim2.fromOffset(20,20),ZIndex=303,Parent=head})
local skipIcon=Icons.themed(skip,"x",12,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=304})
local text=label(panel,"",10,{Name="Text",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,TextTruncate=Enum.TextTruncate.None,LayoutOrder=2,ZIndex=303})
Theme.bind(text,"TextColor3","text")
local foot=create("Frame",{Name="Foot",BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),LayoutOrder=3,ZIndex=302,Parent=panel})
local counter=label(foot,"",9,{Name="Counter",Size=UDim2.new(0,60,1,0),ZIndex=303})
Theme.bind(counter,"TextColor3","muted")
local function footButton(name,primary,x)
local button=create("TextButton",{
Name=name,Text=name,TextSize=9,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,
AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,x,0.5,0),Size=UDim2.fromOffset(Util.textWidth(name,9,Enum.Font.GothamMedium)+20,22),ZIndex=303,Parent=foot,
})
corner(button,6)
local edge=stroke(button)
Theme.bind(button,"BackgroundColor3",primary and"accent"or"input")
Theme.bind(button,"TextColor3",primary and"onAccent"or"text")
Theme.bind(edge,"Color",primary and"accent"or"buttonEdge")
return button
end
local nextButton=footButton("Next",true,0)
local backButton=footButton("Back",false,-(nextButton.Size.X.Offset+6))
local function wrapHeight(value,size,width)
local lines,line=0,""
for paragraph in(tostring(value).."\n"):gmatch("(.-)\n")do
line=""
lines=lines+1
for word in paragraph:gmatch("%S+")do
local try=line==""and word or(line.." "..word)
if line~=""and Util.textWidth(try,size,Enum.Font.Gotham)>width then
lines=lines+1
line=word
else
line=try
end
end
end
return math.max(1,lines)*(size+4)
end
local function rectOf(object)
local p,s=Util.screenPos(object),object.AbsoluteSize
if s.X>0 and s.Y>0 then return p,s end
local x1,y1,x2,y2
for _,child in ipairs(object:GetChildren())do
if child:IsA("GuiObject")and child.Visible and child.AbsoluteSize.X>0 then
local cp,cs=Util.screenPos(child),child.AbsoluteSize
x1=math.min(x1 or cp.X,cp.X)
y1=math.min(y1 or cp.Y,cp.Y)
x2=math.max(x2 or cp.X+cs.X,cp.X+cs.X)
y2=math.max(y2 or cp.Y+cs.Y,cp.Y+cs.Y)
end
end
if not x1 then return p,s end
return Vector2.new(x1,y1),Vector2.new(x2-x1,y2-y1)
end
local current
local function place()
if not alive then return end
local viewport=Util.viewport()
local object=current and guiOf(window,current.Target)
local x,y,w,h
local p,s
if object and object.Parent then p,s=rectOf(object)end
if s and s.X>0 then
x,y,w,h=p.X-PAD,p.Y-PAD,s.X+PAD*2,s.Y+PAD*2
else
x,y,w,h=viewport.X/2,viewport.Y/2,0,0
end
ring.Visible=w>0
ring.Position,ring.Size=UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
panes[1].Position,panes[1].Size=UDim2.fromOffset(0,0),UDim2.new(1,0,0,math.max(0,y))
panes[2].Position,panes[2].Size=UDim2.fromOffset(0,y+h),UDim2.new(1,0,1,-(y+h))
panes[3].Position,panes[3].Size=UDim2.fromOffset(0,y),UDim2.fromOffset(math.max(0,x),h)
panes[4].Position,panes[4].Size=UDim2.fromOffset(x+w,y),UDim2.new(1,-(x+w),0,h)
local pw=PANEL*scale
local ph=math.max(panel.AbsoluteSize.Y,(24+18+6+text.Size.Y.Offset+6+24)*scale)
local px,py
local rightHalf=x+w/2>viewport.X/2
local alignX=rightHalf and(x+w-pw)or x
if w==0 then
px,py=x-pw/2,y-ph/2
elseif h>w*2 and(rightHalf and x-10-pw>=8 or x+w+10+pw<=viewport.X-8)then
px=rightHalf and x-10-pw or x+w+10
py=math.clamp(y+h/2-ph/2,y,y+h-ph)
elseif y+h+10+ph<=viewport.Y-8 then
px,py=alignX,y+h+10
elseif y-10-ph>=8 then
px,py=alignX,y-10-ph
elseif not rightHalf and x+w+10+pw<=viewport.X-8 then
px,py=x+w+10,y
else
px,py=x-10-pw,y
end
px=math.clamp(px,8,math.max(8,viewport.X-pw-8))
py=math.clamp(py,8,math.max(8,viewport.Y-ph-8))
panel.Position=UDim2.fromOffset(px,py)
end
local function show(index)
index=math.clamp(index,1,#steps)
tour.Index=index
current=steps[index]
if current.Target~=nil then reveal(window,current.Target)end
titleLabel.Text=tostring(current.Title or"")
text.Text=tostring(current.Text or"")
text.AutomaticSize=Enum.AutomaticSize.None
text.Size=UDim2.new(1,0,0,wrapHeight(text.Text,10,PANEL-30))
counter.Text=string.format("%d / %d",index,#steps)
nextButton.Text=index==#steps and"Done"or"Next"
nextButton.Size=UDim2.fromOffset(Util.textWidth(nextButton.Text,9,Enum.Font.GothamMedium)+20,22)
backButton.Position=UDim2.new(1,-(nextButton.Size.X.Offset+6),0.5,0)
backButton.Visible=index>1
if type(current.OnShow)=="function"then window:_safe("Tour",current.OnShow)end
place()
task.defer(place)
end
local connections={}
function tour:Close(completed)
if not alive then return end
alive=false
for _,connection in ipairs(connections)do connection:Disconnect()end
overlay:Destroy()
window._tour=nil
if completed~=nil then pcall(window._state,window,"tour:"..id,true)end
if opts.OnFinish then window:_safe("Tour",opts.OnFinish,completed==true)end
end
function tour:Next()if tour.Index>=#steps then tour:Close(true)else show(tour.Index+1)end end
function tour:Back()if tour.Index>1 then show(tour.Index-1)end end
function tour:Go(index)show(tonumber(index)or 1)end
nextButton.Activated:Connect(function()require("sounds").Play("click")tour:Next()end)
backButton.Activated:Connect(function()require("sounds").Play("click")tour:Back()end)
skip.Activated:Connect(function()tour:Close(false)end)
skip.MouseEnter:Connect(function()if skipIcon then Theme.tweenTo(skipIcon,"ImageColor3","heading",0.1)end end)
skip.MouseLeave:Connect(function()if skipIcon then Theme.tweenTo(skipIcon,"ImageColor3","muted",0.1)end end)
connections[#connections+1]=self.maid:connect(Util.Services.RunService.Heartbeat,place)
connections[#connections+1]=self.maid:connect(Util.Services.UserInputService.InputBegan,function(input,processed)
if not alive or processed then return end
local key=input.KeyCode
if key==Enum.KeyCode.Escape then tour:Close(false)
elseif key==Enum.KeyCode.Right or key==Enum.KeyCode.Return then tour:Next()
elseif key==Enum.KeyCode.Left then tour:Back()end
end)
self._tour=tour
show(1)
return tour
end
end
end
__modules["util"]=function()
local Util={}
local cloneref=cloneref or clonereference or function(object)return object end
Util.Services=setmetatable({},{
__index=function(cache,name)
local service=cloneref(game:GetService(name))
rawset(cache,name,service)
return service
end,
})
local Services=Util.Services
local genv=(getgenv and getgenv())or _G
Util.secure=genv.QUSTAH_SECURE==true
function Util.log(message)
if not Util.secure then warn(message)end
end
function Util.create(class,props,children)
local object=Instance.new(class)
local parent
for key,value in pairs(props or{})do
if key=="Parent"then parent=value else object[key]=value end
end
for _,child in ipairs(children or{})do child.Parent=object end
if parent then object.Parent=parent end
return object
end
local create=Util.create
function Util.corner(object,radius)
return create("UICorner",{CornerRadius=UDim.new(0,radius or 6),Parent=object})
end
function Util.stroke(object,color,transparency,thickness)
return create("UIStroke",{
ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=color or Color3.new(1,1,1),
Transparency=transparency or 0,Thickness=thickness or 1,Parent=object,
})
end
function Util.padding(object,left,right,top,bottom)
return create("UIPadding",{
PaddingLeft=UDim.new(0,left or 0),PaddingRight=UDim.new(0,right or left or 0),
PaddingTop=UDim.new(0,top or 0),PaddingBottom=UDim.new(0,bottom or top or 0),Parent=object,
})
end
function Util.list(object,padding,direction,horizontal,vertical)
return create("UIListLayout",{
Padding=UDim.new(0,padding or 0),FillDirection=direction or Enum.FillDirection.Vertical,
HorizontalAlignment=horizontal or Enum.HorizontalAlignment.Left,
VerticalAlignment=vertical or Enum.VerticalAlignment.Top,
SortOrder=Enum.SortOrder.LayoutOrder,Parent=object,
})
end
function Util.uiScale(object)
local scale=1
while object and not object:IsA("LayerCollector")do
local found=object:FindFirstChildWhichIsA("UIScale")
if found then scale=scale*found.Scale end
object=object.Parent
end
return scale
end
function Util.fitCanvas(scroller,source,extra)
local function update()
if not scroller.Parent then return end
local scale=Util.uiScale(scroller)
if scale<=0 then scale=1 end
local height
if source:IsA("UIGridStyleLayout")then
height=source.AbsoluteContentSize.Y/scale
else
height=source.AbsoluteSize.Y/scale+source.Position.Y.Offset
end
if height<=0 then return end
local padding=scroller:FindFirstChildWhichIsA("UIPadding")
if padding then height=height+padding.PaddingTop.Offset+padding.PaddingBottom.Offset end
scroller.AutomaticCanvasSize=Enum.AutomaticSize.None
scroller.CanvasSize=UDim2.new(0,0,0,math.ceil(height+(extra or 0)))
end
source:GetPropertyChangedSignal(source:IsA("UIGridStyleLayout")and"AbsoluteContentSize"or"AbsoluteSize"):Connect(update)
task.defer(update)
return update
end
function Util.label(parent,text,size,props)
local object=create("TextLabel",{
BackgroundTransparency=1,Text=text or"",TextSize=size or 11,Font=Enum.Font.Gotham,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
TextTruncate=Enum.TextTruncate.AtEnd,BorderSizePixel=0,Parent=parent,
})
for key,value in pairs(props or{})do object[key]=value end
return object
end
function Util.tween(object,duration,props,style,direction)
local tween=Services.TweenService:Create(object,
TweenInfo.new(duration,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),props)
tween:Play()
return tween
end
function Util.safe(callback,...)
if type(callback)~="function"then return end
local ok,err=pcall(callback,...)
if not ok then Util.log("[qustah-ui-lib] callback error: "..tostring(err))end
end
function Util.maid()
local maid={items={}}
function maid:give(item)self.items[#self.items+1]=item return item end
function maid:connect(signal,callback)return self:give(signal:Connect(callback))end
function maid:clean()
for index=#self.items,1,-1 do
local item=self.items[index]
self.items[index]=nil
if typeof(item)=="Instance"then
pcall(item.Destroy,item)
elseif type(item)=="function"then
pcall(item)
elseif item and(typeof(item)=="RBXScriptConnection"or type(item)=="table")and item.Disconnect then
pcall(item.Disconnect,item)
end
end
end
return maid
end
function Util.textWidth(text,size,font)
return Services.TextService:GetTextSize(tostring(text),size,font or Enum.Font.Gotham,Vector2.new(10000,100)).X
end
function Util.round(value,step)
step=step or 1
if step<=0 then return value end
return math.floor(value/step+0.5)*step
end
function Util.decimals(step)
local text=tostring(step)
local dot=text:find("%.")
return dot and#text-dot or 0
end
function Util.toHex(color)
return string.format("%02X%02X%02X",math.floor(color.R*255+0.5),math.floor(color.G*255+0.5),math.floor(color.B*255+0.5))
end
function Util.fromHex(text)
text=tostring(text or""):gsub("#",""):gsub("%s","")
if not text:match("^%x%x%x%x%x%x$")then return nil end
return Color3.fromRGB(tonumber(text:sub(1,2),16),tonumber(text:sub(3,4),16),tonumber(text:sub(5,6),16))
end
local SHORT_KEYS={
LeftShift="LSHIFT",RightShift="RSHIFT",LeftControl="LCTRL",RightControl="RCTRL",
LeftAlt="LALT",RightAlt="RALT",MouseButton1="M1",MouseButton2="M2",MouseButton3="M3",Return="ENTER",
KeypadZero="NUM 0",KeypadOne="NUM 1",KeypadTwo="NUM 2",KeypadThree="NUM 3",KeypadFour="NUM 4",
KeypadFive="NUM 5",KeypadSix="NUM 6",KeypadSeven="NUM 7",KeypadEight="NUM 8",KeypadNine="NUM 9",
}
function Util.keyName(key)
if key==nil then return"None"end
local name=typeof(key)=="EnumItem"and key.Name or tostring(key)
if name=="None"or name==""or name=="Unknown"then return"None"end
return SHORT_KEYS[name]or name:upper()
end
function Util.toKey(name)
if typeof(name)=="EnumItem"then return name end
if type(name)~="string"or name==""or name=="None"then return nil end
if name:match("^MouseButton%d$")then
local found,button=pcall(function()return Enum.UserInputType[name]end)
if found and button then return button end
end
local ok,key=pcall(function()return Enum.KeyCode[name]end)
if ok and key then return key end
ok,key=pcall(function()return Enum.UserInputType[name]end)
if ok and key then return key end
return nil
end
function Util.inputKey(input,allowPrimary)
if input.UserInputType==Enum.UserInputType.Keyboard then return input.KeyCode end
if input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton3 then
return input.UserInputType
end
if allowPrimary and input.UserInputType==Enum.UserInputType.MouseButton1 then return input.UserInputType end
return nil
end
local MODIFIERS={
LeftShift=true,RightShift=true,LeftControl=true,RightControl=true,LeftAlt=true,RightAlt=true,
}
function Util.isModifier(key)return typeof(key)=="EnumItem"and MODIFIERS[key.Name]==true end
function Util.isDown(key)
if typeof(key)~="EnumItem"then return false end
local UserInputService=Services.UserInputService
local ok,down=pcall(function()
if tostring(key):match("^Enum%.KeyCode%.")then return UserInputService:IsKeyDown(key)end
return UserInputService:IsMouseButtonPressed(key)
end)
return ok and down==true
end
local probes=setmetatable({},{__mode="k"})
function Util.origin(object)
local gui=object and object:FindFirstAncestorWhichIsA("LayerCollector")
if not gui then return Vector2.new(0,0)end
local probe=probes[gui]
if not probe or probe.Parent~=gui then
probe=Instance.new("Frame")
probe.Name="Origin"
probe.BackgroundTransparency=1
probe.Size=UDim2.fromOffset(0,0)
probe.Position=UDim2.fromOffset(0,0)
probe.Parent=gui
probes[gui]=probe
end
return probe.AbsolutePosition
end
function Util.screenPos(object)
return object.AbsolutePosition-Util.origin(object)
end
function Util.pointer(input)
if input and input.UserInputType==Enum.UserInputType.Touch then
local inset=Services.GuiService:GetGuiInset()
return Vector2.new(input.Position.X+inset.X,input.Position.Y+inset.Y)
end
return Services.UserInputService:GetMouseLocation()
end
function Util.isPress(input)
return input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch
end
function Util.avatar(userId,size)
size=size or 48
return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d",tonumber(userId)or 0,size,size)
end
function Util.fadeScrollbar(scroller,shown)
shown=shown or 0.35
local hovering,token=false,0
scroller.ScrollBarImageTransparency=1
local function show()
token=token+1
local mine=token
Util.tween(scroller,0.12,{ScrollBarImageTransparency=shown})
task.delay(1.2,function()
if mine==token and not hovering and scroller.Parent then Util.tween(scroller,0.35,{ScrollBarImageTransparency=1})end
end)
end
scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(show)
scroller.MouseEnter:Connect(function()hovering=true show()end)
scroller.MouseLeave:Connect(function()hovering=false show()end)
return scroller
end
function Util.isTouch()
local UserInputService=Services.UserInputService
local ok,touch=pcall(function()return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end)
return ok and touch==true
end
function Util.hoverPop(button,amount)
local scale=create("UIScale",{Scale=1,Parent=button})
button.MouseEnter:Connect(function()Util.tween(scale,0.12,{Scale=amount or 1.05})end)
button.MouseLeave:Connect(function()Util.tween(scale,0.15,{Scale=1})end)
return scale
end
function Util.clock(seconds)
seconds=math.max(0,math.floor(seconds))
return string.format("%02d:%02d:%02d",seconds//3600,(seconds//60)%60,seconds%60)
end
function Util.viewport()
local camera=workspace.CurrentCamera
return camera and camera.ViewportSize or Vector2.new(1280,720)
end
function Util.guiParent()
local ok,hidden=pcall(function()return gethui and gethui()end)
if ok and hidden then return hidden end
local probe=Instance.new("Folder")
local coreOk=pcall(function()probe.Parent=Services.CoreGui end)
probe:Destroy()
if coreOk then return Services.CoreGui end
return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end
function Util.screenGui(name,order)
local gui=create("ScreenGui",{
Name=Util.secure and Services.HttpService:GenerateGUID(false)or name,ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=order or 50,
ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})
pcall(function()if syn and syn.protect_gui then syn.protect_gui(gui)elseif protectgui then protectgui(gui)end end)
gui.Parent=Util.guiParent()
return gui
end
function Util.writeAtomic(path,text)
if type(writefile)~="function"then return false,"writefile is not available"end
local tmp=path..".tmp"
local ok,err=pcall(writefile,tmp,text)
if not ok then return false,tostring(err)end
if type(readfile)=="function"then
local read,back=pcall(readfile,tmp)
if not read or(back~=text and(tostring(back):gsub("\r\n","\n"))~=(text:gsub("\r\n","\n")))then
return false,"the file could not be written completely"
end
end
ok,err=pcall(writefile,path,text)
if not ok then return false,tostring(err)end
if type(delfile)=="function"then pcall(delfile,tmp)end
return true
end
function Util.readJSON(path)
if type(isfile)~="function"or type(readfile)~="function"then return nil,"missing"end
local function decode(file)
if not isfile(file)then return nil,"missing"end
local ok,data=pcall(function()return Services.HttpService:JSONDecode(readfile(file))end)
if ok and type(data)=="table"then return data end
return nil,"damaged"
end
local tmp=path..".tmp"
local data,problem=decode(path)
if data then
if isfile(tmp)then
local newer=decode(tmp)
local read,saved,current=pcall(function()return readfile(tmp),readfile(path)end)
if newer and read and saved~=current then
pcall(function()writefile(path,readfile(tmp))end)
if type(delfile)=="function"then pcall(delfile,tmp)end
return newer,true
end
if type(delfile)=="function"then pcall(delfile,tmp)end
end
return data,false
end
local saved=decode(tmp)
if saved then
pcall(function()writefile(path,readfile(tmp))end)
if type(delfile)=="function"then pcall(delfile,tmp)end
return saved,true
end
return nil,problem
end
local B64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function Util.base64encode(data)
local out={}
for i=1,#data,3 do
local a,b,c=data:byte(i,i+2)
local n=a*65536+(b or 0)*256+(c or 0)
local c1,c2,c3,c4=n//262144,(n//4096)%64,(n//64)%64,n%64
out[#out+1]=B64:sub(c1+1,c1+1)..B64:sub(c2+1,c2+1)
..(b and B64:sub(c3+1,c3+1)or"=")..(c and B64:sub(c4+1,c4+1)or"=")
end
return table.concat(out)
end
function Util.base64decode(data)
data=tostring(data):gsub("[^%w%+/=]","")
local out,bits,count={},0,0
for i=1,#data do
local char=data:sub(i,i)
if char=="="then break end
local value=B64:find(char,1,true)
if not value then return nil end
bits=bits*64+(value-1)
count=count+6
if count>=8 then
count=count-8
out[#out+1]=string.char((bits//(2^count))%256)
bits=bits%(2^count)
end
end
return table.concat(out)
end
function Util.ago(time)
local seconds=math.max(0,os.time()-(tonumber(time)or os.time()))
if seconds<60 then return"now"end
if seconds<3600 then return(seconds//60).."m ago"end
if seconds<86400 then return(seconds//3600).."h ago"end
return(seconds//86400).."d ago"
end
return Util
end
__modules["window"]=function()
local Util=require("util")
local Theme=require("theme")
local Card=require("card")
local Config=require("config")
local Glow=require("glow")
local UIFont=require("font")
local Icons=require("icons")
local Services=Util.Services
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
local HEADER,FOOTER=44,26
local DOCK_WIDTH,DOCK_GAP,DOCK_BUTTON,DOCK_STEP,DOCK_TOP=40,12,30,37,42
local HINTS=34
local NARROW=470
local Window={}
Window.__index=Window
local Tab={}
Tab.__index=Tab
local Page={}
Page.__index=Page
function Page.new(tab,name,cfg)
local window=tab.window
local self=setmetatable({tab=tab,window=window,Name=name,cfg=cfg or{},cards=0,order=0},Page)
local frame=create("ScrollingFrame",{
Name=name,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),
CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,
ScrollBarThickness=2,ScrollBarImageTransparency=0.4,ElasticBehavior=Enum.ElasticBehavior.Never,
VerticalScrollBarInset=Enum.ScrollBarInset.ScrollBar,Visible=false,Parent=window.pages,
})
Theme.bind(frame,"ScrollBarImageColor3","muted")
Util.fadeScrollbar(frame,0.4)
local content=create("Frame",{
Name="Content",BackgroundTransparency=1,Position=UDim2.fromOffset(16,2),Size=UDim2.new(1,-30,0,0),
AutomaticSize=Enum.AutomaticSize.Y,Parent=frame,
})
Util.list(content,10)
Util.padding(content,0,0,0,14)
Util.fitCanvas(frame,content)
local wide=create("Frame",{Name="Wide",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=content})
Util.list(wide,10)
local holder=create("Frame",{
Name="Columns",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
LayoutOrder=2,Parent=content,
})
self.layout=Util.list(holder,10,Enum.FillDirection.Horizontal)
local function column(name,order)
local object=create("Frame",{
Name=name,BackgroundTransparency=1,Size=UDim2.new(0.5,-5,0,0),AutomaticSize=Enum.AutomaticSize.Y,
LayoutOrder=order,Parent=holder,
})
Util.list(object,10)
return object
end
self.frame,self.wide,self.left,self.right=frame,wide,column("Left",1),column("Right",2)
self.content=content
if self.cfg.Warning then task.defer(function()self:Warning(self.cfg.Warning)end)end
local function fade(top)
local object=create("Frame",{
Name=top and"FadeTop"or"FadeBottom",AnchorPoint=Vector2.new(0,top and 0 or 1),
Position=UDim2.new(0,0,top and 0 or 1,0),Size=UDim2.new(1,-4,0,18),BorderSizePixel=0,
Visible=false,ZIndex=20,Active=false,Parent=window.pages,
})
Theme.bind(object,"BackgroundColor3","base")
create("UIGradient",{Rotation=90,Transparency=NumberSequence.new(top and 0 or 1,top and 1 or 0),Parent=object})
return object
end
local fadeTop,fadeBottom=fade(true),fade(false)
local function refreshFades()
local shown=frame.Visible
local scrolled=frame.CanvasPosition.Y
local hidden=frame.AbsoluteCanvasSize.Y-frame.AbsoluteWindowSize.Y-scrolled
fadeTop.Visible=shown and scrolled>2
fadeBottom.Visible=shown and hidden>2
end
for _,property in ipairs({"CanvasPosition","AbsoluteCanvasSize","AbsoluteWindowSize","Visible"})do
frame:GetPropertyChangedSignal(property):Connect(refreshFades)
end
local button=create("TextButton",{
Name=name,BackgroundTransparency=1,Text=name,TextSize=10,Font=Enum.Font.GothamMedium,
AutoButtonColor=false,Parent=tab.strip,
})
Theme.bind(button,"TextColor3","text")
local underline=create("Frame",{
Name="Underline",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),
Size=UDim2.fromOffset(math.max(12,Util.textWidth(name,10,Enum.Font.GothamMedium)),1),
BorderSizePixel=0,Visible=false,Parent=button,
})
Theme.bind(underline,"BackgroundColor3","accent")
self.button,self.underline=button,underline
button.MouseEnter:Connect(function()if tab.current~=self then Theme.tweenTo(button,"TextColor3","heading",0.12)end end)
button.MouseLeave:Connect(function()if tab.current~=self then Theme.tweenTo(button,"TextColor3","text",0.12)end end)
button.Activated:Connect(function()self:Select()end)
self:_columns(window.width)
return self
end
function Page:_columns(width)
local single=self.cfg.Columns==1 or width<NARROW
self.layout.FillDirection=single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
local size=single and UDim2.new(1,0,0,0)or UDim2.new(0.5,-5,0,0)
self.left.Size,self.right.Size=size,size
end
function Page:Warning(text,opts)
opts=opts or{}
local level=opts.Level or"warning"
local role=level=="info"and"accent"or level
local banner=create("Frame",{Name="Warning",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,LayoutOrder=0,Parent=self.content})
Theme.bind(banner,"BackgroundColor3",role)
banner.BackgroundTransparency=0.88
corner(banner,8)
local edge=stroke(banner)
Theme.bind(edge,"Color",role)
edge.Transparency=0.55
Util.padding(banner,12,12,9,9)
local Icons=require("icons")
local icon=Icons.themed(banner,opts.Icon or(level=="info"and"info"or"triangle-alert"),15,role,{Position=UDim2.fromOffset(0,1)})
local column=create("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(icon and 26 or 0,0),Size=UDim2.new(1,icon and-26 or 0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=banner})
Util.list(column,2)
local title
if opts.Title then
title=label(column,tostring(opts.Title),11,{Name="Title",Size=UDim2.new(1,0,0,16),Font=Enum.Font.GothamMedium,LayoutOrder=1})
Theme.bind(title,"TextColor3",role)
end
local body=label(column,tostring(text or""),10,{
Name="Text",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,
TextTruncate=Enum.TextTruncate.None,RichText=true,LayoutOrder=2,
})
Theme.bind(body,"TextColor3","heading")
local handle={Frame=banner,Icon=icon}
function handle:SetText(value)body.Text=tostring(value)end
function handle:SetVisible(visible)banner.Visible=visible~=false end
return handle
end
function Page:Card(cfg)
cfg=cfg or{}
self.cards=self.cards+1
local side=cfg.Side
if self.cfg.Columns==1 then side="Left"end
if side~="Left"and side~="Right"then side=(self.cards%2==1)and"Left"or"Right"end
self.order=self.order+1
if cfg.Wide then
self.cards=self.cards-1
return Card.new(self,self.wide,cfg,self.order)
end
return Card.new(self,side=="Right"and self.right or self.left,cfg,self.order)
end
function Page:Select()
local tab=self.tab
tab.current=self
for _,page in ipairs(tab.Pages)do
local selected=page==self
page.frame.Visible=selected and tab.window.current==tab
page.underline.Visible=selected
Theme.tweenTo(page.button,"TextColor3",selected and"accent"or"text",0.12)
end
tab.window:_updateLocation()
end
function Tab.new(window,cfg)
local index=#window.Tabs+1
local self=setmetatable({window=window,Title=cfg.Title or("Tab "..index),Pages={},index=index},Tab)
self.strip=create("Frame",{Name=self.Title,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=false,Parent=window.stripHolder})
self.Header=cfg.Header==true
self._build=type(cfg.Build)=="function"and cfg.Build or nil
if self._build and cfg.BuildDelay~=false then
task.delay(tonumber(cfg.BuildDelay)or 1.5,function()
if self._build and window.alive then self:Build()end
end)
end
self.Divider=cfg.Divider==true or window._dividerNext==true
window._dividerNext=nil
local button=create("TextButton",{
Name=self.Title.."Tab",BackgroundTransparency=1,Text="",AutoButtonColor=false,BorderSizePixel=0,
Position=UDim2.fromOffset(5,DOCK_TOP),Size=UDim2.fromOffset(DOCK_BUTTON,DOCK_BUTTON),ZIndex=42,Parent=window.dock,
})
Theme.bind(button,"BackgroundColor3","accentDeep")
corner(button,15)
local icon
if cfg.Icon~=nil and Icons.Get(cfg.Icon)then
icon=create("ImageLabel",{
Name="Icon",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(18,18),
BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=43,Parent=button,
})
Icons.Apply(icon,cfg.Icon)
self.iconProperty="ImageColor3"
else
icon=label(button,self.Title:sub(1,1):upper(),13,{
Name="Icon",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=43,
})
self.iconProperty="TextColor3"
end
self.button,self.icon,self.hovered=button,icon,false
self:_render(false)
button.MouseEnter:Connect(function()
self.hovered=true
self:_render(true)
window:_dockTip(self.Title,self.y or DOCK_TOP)
end)
button.MouseLeave:Connect(function()
self.hovered=false
self:_render(true)
window:_hideTip()
end)
button.Activated:Connect(function()
window:_hideTip()
if window.current~=self then require("sounds").Play("tab")end
self:Select()
end)
return self
end
function Tab:_render(animate)
local selected=self.window.current==self
local duration=animate and 0.14 or nil
local transparency=selected and 0 or(self.hovered and 0.6 or 1)
if duration then tween(self.button,duration,{BackgroundTransparency=transparency})else self.button.BackgroundTransparency=transparency end
Theme.tweenTo(self.icon,self.iconProperty,selected and"accent"or(self.hovered and"heading"or"icon"),duration)
end
function Tab:SetBadge(value,color)
local shown=value~=nil and value~=false and value~=0 and tostring(value)~=""and tostring(value)~="0"
self.Badge=shown and value or nil
if not shown then
if self._badge then self._badge.Visible=false end
return
end
local badge=self._badge
if not badge then
badge=create("Frame",{Name="Badge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,2,0,-1),BorderSizePixel=0,ZIndex=45,Parent=self.button})
corner(badge,7)
local text=label(badge,"",8,{Name="Text",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=46})
local ring=Util.stroke(badge,nil,0,1.5)
Theme.bind(ring,"Color","dock")
self._badge,self._badgeText=badge,text
end
local role=color or"accent"
Theme.bind(badge,"BackgroundColor3",role)
Theme.bind(self._badgeText,"TextColor3",role=="accent"and"onAccent"or"heading")
if value==true then
self._badgeText.Text=""
badge.Size=UDim2.fromOffset(8,8)
badge.Position=UDim2.new(1,0,0,1)
else
local text=tostring(value)
if tonumber(value)and tonumber(value)>99 then text="99+"end
self._badgeText.Text=text
badge.Size=UDim2.fromOffset(math.max(14,Util.textWidth(text,8,Enum.Font.GothamBold)+8),14)
badge.Position=UDim2.new(1,3,0,-2)
end
badge.Visible=true
end
function Tab:Page(name,cfg)
local page=Page.new(self,tostring(name or("Page "..(#self.Pages+1))),cfg)
self.Pages[#self.Pages+1]=page
local count=#self.Pages
for index,item in ipairs(self.Pages)do
item.button.Position=UDim2.new((index-1)/count,0,0,0)
item.button.Size=UDim2.new(1/count,0,1,0)
end
if not self.current then self.current=page end
if self.window.current==self then self:Select()end
return page
end
function Tab:Card(cfg)
if#self.Pages==0 then self:Page(self.Title)end
return self.Pages[1]:Card(cfg)
end
function Tab:Build()
local build=self._build
if not build then return end
self._build=nil
self.window:_safe("Build "..self.Title,build,self)
end
function Tab:Select()
local window=self.window
if self._build then self:Build()end
window.current=self
for _,tab in ipairs(window.Tabs)do
tab.strip.Visible=tab==self and#tab.Pages>1
for _,page in ipairs(tab.Pages)do page.frame.Visible=false end
tab:_render(true)
end
window:_layoutBody()
local page=self.current or self.Pages[1]
if page then page:Select()else window:_updateLocation()end
end
function Window.new(Lib,cfg)
cfg=cfg or{}
local size=cfg.Size or Vector2.new(540,390)
local self=setmetatable({
Lib=Lib,cfg=cfg,Title=tostring(cfg.Title or"Qustah UI"),Version=tostring(cfg.Version or""),
Tabs={},flags={},binds={},maid=Util.maid(),
width=size.X,height=size.Y,
minSize=cfg.MinSize or Vector2.new(400,300),maxSize=cfg.MaxSize or Vector2.new(920,660),
key=cfg.ToggleKey or Enum.KeyCode.RightShift,visible=true,folded=false,alive=true,
},Window)
task.delay(3,function()self._keysSettled=true end)
local env=(getgenv and getgenv())or _G
env.__QustahUIWindows=env.__QustahUIWindows or{}
local previous=env.__QustahUIWindows[self.Title]
if previous and previous.Destroy then
pcall(previous.Destroy,previous)
local oldLib=previous.Lib
if oldLib and oldLib~=Lib and type(oldLib.Windows)=="table"and#oldLib.Windows==0 and oldLib.Destroy then pcall(oldLib.Destroy,oldLib)end
end
env.__QustahUIWindows[self.Title]=self
if typeof(cfg.Accent)=="Color3"then Theme.set("accent",cfg.Accent)end
if cfg.Secure then Util.secure=true end
if cfg.Sounds~=nil then require("sounds").Enabled=cfg.Sounds==true end
self:_makeFlags()
self.Config=Config.new(self,cfg.Folder or self.Title:gsub("[^%w_%- ]",""))
self.Config:OnRecovered(function(name)
task.defer(function()
if self.alive then self:Notify({Title="Restored "..tostring(name),Content="It was saved when the game closed - nothing was lost",Icon="history",Color="warning"})end
end)
end)
self.memory=cfg.SaveWindow~=false and self.Config:ReadMemory()or{}
local perGame=self.memory.perGame
if perGame==nil then perGame=cfg.PerGame end
if perGame then self.Config:SetPerGame(perGame)end
local saved=self.memory.window
if type(saved)=="table"and tonumber(saved.w)and tonumber(saved.h)then
self.width=math.clamp(tonumber(saved.w),self.minSize.X,self.maxSize.X)
self.height=math.clamp(tonumber(saved.h),self.minSize.Y,self.maxSize.Y)
end
self.uiScale=math.clamp(tonumber(self.memory.uiScale or cfg.Scale)or 1,0.6,1.5)
Glow.start(Lib.maid)
self:_build()
if self._buildExtras then self:_buildExtras()end
if self._buildInbox then self:_buildInbox()end
if self._buildFx then self:_buildFx()end
if self._watchKicks then self:_watchKicks()end
if self._buildMobile then self:_buildMobile()end
self:_refreshStatus()
Lib.Windows[#Lib.Windows+1]=self
return self
end
function Window:_build()
local maid=self.maid
local gui=Util.screenGui("QustahUI_"..self.Title:gsub("%W",""),50)
maid:give(gui)
self.gui=gui
UIFont.register(gui,maid)
local main=create("CanvasGroup",{
Name="Window",Size=UDim2.fromOffset(self.width,self.height),BorderSizePixel=0,
GroupTransparency=0,ClipsDescendants=true,Parent=gui,
})
Theme.bind(main,"BackgroundColor3","base")
corner(main,12)
self.mainStroke=stroke(main)
Theme.bind(self.mainStroke,"Color","edge")
self.main=main
self.scale=create("UIScale",{Scale=1,Parent=main})
local header=create("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,-90,0,HEADER),Active=true,Parent=main})
local titleRow=create("Frame",{Name="TitleRow",BackgroundTransparency=1,Position=UDim2.fromOffset(16,0),Size=UDim2.new(1,-16,1,0),Parent=header})
Util.list(titleRow,6,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
local title=label(titleRow,self.Title,16,{
Name="Title",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,24),
TextTruncate=Enum.TextTruncate.None,LayoutOrder=1,
})
pcall(function()title.FontFace=Font.new(Font.fromEnum(Enum.Font.Gotham).Family,Enum.FontWeight.SemiBold)end)
Theme.bind(title,"TextColor3","accent")
Glow.add(title,{Base="accent",Period=3.6,GlowTransparency=0.8})
if self.cfg.Icon then
local logo=Icons.themed(titleRow,self.cfg.Icon,18,"accent",{Name="Logo",LayoutOrder=0})
if logo then self.logo=logo end
end
if self.Version~=""then
local badge=create("Frame",{Name="Version",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,16),LayoutOrder=2,Parent=titleRow})
Theme.bind(badge,"BackgroundColor3","card")
corner(badge,6)
Theme.bind(stroke(badge,nil,0.5),"Color","accent")
Util.padding(badge,6,6,0,0)
local text=label(badge,self.Version,9,{
AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromScale(0,1),TextXAlignment=Enum.TextXAlignment.Center,
TextTruncate=Enum.TextTruncate.None,
})
Theme.bind(text,"TextColor3","accent")
end
self.titleLabel,self.titleRow=title,titleRow
local function windowButton(name,offset,cross,bare)
local button=create("TextButton",{
Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,
Position=UDim2.new(1,offset,0,8),Size=UDim2.fromOffset(30,28),Parent=main,
})
corner(button,6)
Theme.bind(button,"BackgroundColor3","input")
local bars={}
for _,rotation in ipairs(bare and{}or(cross and{45,-45}or{0}))do
local bar=create("Frame",{
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(10,2),
Rotation=rotation,BorderSizePixel=0,Parent=button,
})
corner(bar,1)
Theme.bind(bar,"BackgroundColor3","muted")
bars[#bars+1]=bar
end
button.MouseEnter:Connect(function()
tween(button,0.12,{BackgroundTransparency=0,BackgroundColor3=Theme.get(cross and"dangerDeep"or"input")})
for _,bar in ipairs(bars)do Theme.tweenTo(bar,"BackgroundColor3",cross and"danger"or"heading",0.12)end
end)
button.MouseLeave:Connect(function()
tween(button,0.12,{BackgroundTransparency=1})
for _,bar in ipairs(bars)do Theme.tweenTo(bar,"BackgroundColor3","muted",0.12)end
end)
return button
end
local minimize=windowButton("Minimize",-74,false)
local close=windowButton("Close",-40,true)
self._windowButton=windowButton
self.headerRight=90
local headerLine=create("Frame",{Name="HeaderLine",Position=UDim2.fromOffset(18,HEADER),Size=UDim2.new(1,-36,0,1),BorderSizePixel=0,Parent=main})
Theme.bind(headerLine,"BackgroundColor3","accent")
create("UIGradient",{
Transparency=NumberSequence.new({
NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.45),NumberSequenceKeypoint.new(1,1),
}),Parent=headerLine,
})
local location=label(main,"",10,{
Name="Location",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-self.headerRight,0,12),Size=UDim2.new(0.45,0,0,20),
TextXAlignment=Enum.TextXAlignment.Right,
})
Theme.bind(location,"TextColor3","muted")
self.locationLabel=location
self.headerTabs=create("Frame",{
Name="HeaderTabs",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-self.headerRight,0,0),
Size=UDim2.new(0,0,0,HEADER),AutomaticSize=Enum.AutomaticSize.X,Visible=false,Parent=main,
})
Util.list(self.headerTabs,6,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right)
local body=create("Frame",{
Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(0,HEADER+1),
Size=UDim2.new(1,0,1,-(HEADER+1+FOOTER)),ClipsDescendants=true,Parent=main,
})
self.body=body
self.stripHolder=create("Frame",{Name="Strip",BackgroundTransparency=1,Position=UDim2.fromOffset(16,6),Size=UDim2.new(1,-32,0,26),Parent=body})
self.pages=create("Frame",{Name="Pages",BackgroundTransparency=1,Position=UDim2.fromOffset(0,6),Size=UDim2.new(1,0,1,-6),Parent=body})
self.hintBar=create("Frame",{Name="KeyHints",BackgroundTransparency=1,Position=UDim2.new(0,20,1,-30),Size=UDim2.new(1,-40,0,26),Visible=false,Parent=body})
self.hintLeft=create("Frame",{Name="Left",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Parent=self.hintBar})
Util.list(self.hintLeft,8,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
self.hintRight=create("Frame",{Name="Right",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Parent=self.hintBar})
Util.list(self.hintRight,8,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)
self.hints={}
local footer=create("Frame",{Name="Footer",Position=UDim2.new(0,0,1,-FOOTER),Size=UDim2.new(1,0,0,FOOTER),BorderSizePixel=0,Parent=main})
Theme.bind(footer,"BackgroundColor3","footer")
local footerLine=create("Frame",{Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundTransparency=0.45,Parent=footer})
Theme.bind(footerLine,"BackgroundColor3","line")
local dot=create("ImageLabel",{
Name="StatusDot",Image="rbxassetid://122485335253573",BackgroundTransparency=1,BorderSizePixel=0,
AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,19,0.5,0),Size=UDim2.fromOffset(10,10),Parent=footer,
})
Theme.bind(dot,"ImageColor3","success")
local status=label(footer,"Connected",9,{Name="Status",Position=UDim2.fromOffset(34,0),Size=UDim2.new(0,160,1,0)})
Theme.bind(status,"TextColor3","muted")
Glow.add(status,{Base="muted",Shine="heading",GlowTransparency=0.92})
local centre=label(footer,tostring(self.cfg.Footer or""),9,{
Name="Centre",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.fromScale(0.5,0),Size=UDim2.new(1,-240,1,0),
TextXAlignment=Enum.TextXAlignment.Center,
})
Theme.bind(centre,"TextColor3","muted")
self.footer,self.statusDot,self.statusLabel,self.footerText=footer,dot,status,centre
if self.cfg.Footer==nil then
task.spawn(function()
local ok,info=pcall(function()return Services.MarketplaceService:GetProductInfo(game.PlaceId)end)
if ok and type(info)=="table"and info.Name and centre.Parent and centre.Text==""then centre.Text=tostring(info.Name)end
end)
end
local grip=create("TextButton",{
Name="ResizeGrip",Text="",AutoButtonColor=false,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),
Position=UDim2.new(1,-4,1,-4),Size=UDim2.fromOffset(18,18),ZIndex=10,Parent=main,
})
for _,line in ipairs({{10,10,9},{13,13,4}})do
local mark=create("Frame",{
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(line[1],line[2]),Size=UDim2.fromOffset(line[3],1),
Rotation=-45,BorderSizePixel=0,ZIndex=11,Parent=grip,
})
Theme.bind(mark,"BackgroundColor3","muted")
end
self.grip=grip
local dock=create("CanvasGroup",{Name="Dock",Size=UDim2.fromOffset(DOCK_WIDTH,DOCK_TOP),BorderSizePixel=0,BackgroundTransparency=0.03,ZIndex=40,ClipsDescendants=true,Parent=gui})
Theme.bind(dock,"BackgroundColor3","dock")
corner(dock,20)
Theme.bind(stroke(dock),"Color","line")
self.dock=dock
self.dockScale=create("UIScale",{Scale=1,Parent=dock})
local dockGrip=create("TextButton",{Name="DragHandle",Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(5,6),Size=UDim2.fromOffset(30,28),ZIndex=42,Parent=dock})
for _,lineY in ipairs({9,13,17})do
local bar=create("Frame",{Position=UDim2.fromOffset(9,lineY),Size=UDim2.fromOffset(12,1),BorderSizePixel=0,ZIndex=43,Parent=dockGrip})
Theme.bind(bar,"BackgroundColor3","muted")
end
self.dockGrip,self.dockDividers=dockGrip,{}
local tip=create("Frame",{Name="Tooltip",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,22),BorderSizePixel=0,Visible=false,ZIndex=300,Parent=gui})
Theme.bind(tip,"BackgroundColor3","card")
corner(tip,6)
Theme.bind(stroke(tip),"Color","line")
Util.padding(tip,8,8,0,0)
local tipText=label(tip,"",10,{AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromScale(0,1),ZIndex=301,TextTruncate=Enum.TextTruncate.None})
Theme.bind(tipText,"TextColor3","heading")
self.tip,self.tipText=tip,tipText
local function moveWindow(input)
if not Util.isPress(input)then return end
local start,origin=Util.pointer(input),self.topLeft
self:_hideTip()
self:_beginDrag(input,function(point)
self.topLeft=origin+(point-start)
self:_layout()
end,function()self:_saveMemory()end)
end
maid:connect(header.InputBegan,moveWindow)
maid:connect(dockGrip.InputBegan,moveWindow)
maid:connect(dockGrip.MouseEnter,function()self:_dockTip("Drag",6)end)
maid:connect(dockGrip.MouseLeave,function()self:_hideTip()end)
maid:connect(grip.InputBegan,function(input)
if not Util.isPress(input)or self.folded then return end
local start,width,height=Util.pointer(input),self.width,self.height
self:_beginDrag(input,function(point)
local s=self.scale.Scale
self.width=math.clamp(math.floor(width+(point.X-start.X)/s),self.minSize.X,self.maxSize.X)
self.height=math.clamp(math.floor(height+(point.Y-start.Y)/s),self.minSize.Y,self.maxSize.Y)
self:_layout()
end,function()self:_saveMemory()end)
end)
maid:connect(minimize.Activated,function()self:Minimize()end)
maid:connect(close.Activated,function()
if self.cfg.CloseAction=="Destroy"then
self:Notify({Title=self.Title,Content="Unloaded"})
self:Destroy()
return
end
self:SetVisible(false)
local how=self.mobileButton and"Tap the "..self.Title.." button to open it again"or("Press "..Util.keyName(self.key).." to open it again")
self:Notify({Title=self.Title.." hidden",Content=how})
end)
local UserInputService=Services.UserInputService
maid:connect(UserInputService.InputChanged,function(input)
local drag=self._drag
if not drag then return end
if input.UserInputType==Enum.UserInputType.MouseMovement or(input.UserInputType==Enum.UserInputType.Touch and input==drag.input)then
Util.safe(drag.move,Util.pointer(input))
end
end)
maid:connect(UserInputService.InputEnded,function(input)
local drag=self._drag
if drag and(input.UserInputType==Enum.UserInputType.MouseButton1 or input==drag.input)then
self._drag=nil
Util.safe(drag.finish)
end
end)
maid:connect(UserInputService.InputEnded,function(input)
local key=Util.inputKey(input,true)
if not key then return end
for element,bound in pairs(self.binds)do
if element._onRelease and element.Row and element.Row.Parent then
local target=element.Chord and element.Chord[2]or bound
if target==key then self:_safe(element.Title or"Keybind",element._onRelease,element)end
end
end
end)
maid:connect(UserInputService.InputBegan,function(input,processed)
if self._capture then
local key=Util.inputKey(input,self._captureMouse)
if key then
local capture=self._capture
self._capture=nil
Util.safe(capture,key)
return
end
end
if self._popup and Util.isPress(input)then
local point=Util.pointer(input)
local function inside(object)
if not object or not object.Parent then return false end
local p,s=Util.screenPos(object),object.AbsoluteSize
return point.X>=p.X and point.X<=p.X+s.X and point.Y>=p.Y and point.Y<=p.Y+s.Y
end
if not inside(self._popup.frame)and not inside(self._popup.owner)then self:_closePopup()end
end
if self._dialog and input.KeyCode==Enum.KeyCode.Escape then self._dialog:Close()return end
if processed or UserInputService:GetFocusedTextBox()then return end
local key=Util.inputKey(input,true)
if not key then return end
if key==self.key then self:Toggle()return end
for element,bound in pairs(self.binds)do
if element.Row and element.Row.Parent then
local chord=element.Chord
if chord then
if chord[2]==key and(chord[1]==nil or Util.isDown(chord[1]))then self:_safe(element.Title or"Keybind",element._onBind,element)end
elseif bound==key and key~=Enum.UserInputType.MouseButton1 then
self:_safe(element.Title or"Keybind",element._onBind,element)
end
end
end
end)
if self.cfg.KeyHints~=false then
self.menuHint=self:KeyHint({Title="MENU",Side="Right",Key=self.key,Menu=true,Callback=function(key)self:SetToggleKey(key)end})
end
local function watchCamera()
local camera=workspace.CurrentCamera
if camera then
maid:connect(camera:GetPropertyChangedSignal("ViewportSize"),function()
self:_layout()
for _,place in ipairs(self._placers or{})do Util.safe(place)end
end)
end
self:_layout()
end
maid:connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
watchCamera()
end
function Window:_layout()
if not self.alive then return end
local viewport=Util.viewport()
local total=self.width+DOCK_GAP+DOCK_WIDTH
local s=math.clamp(math.min(self.uiScale or 1,(viewport.X-24)/total,(viewport.Y-24)/self.height),0.4,1.5)
self.scale.Scale,self.dockScale.Scale=s,s
local height=self.folded and HEADER or self.height
self.main.Size=UDim2.fromOffset(self.width,height)
if not self.topLeft then
local saved=self.memory and self.memory.window
if type(saved)=="table"and tonumber(saved.x)and tonumber(saved.y)then
local room=Vector2.new(viewport.X-total*s,viewport.Y-self.height*s)
self.topLeft=Vector2.new(tonumber(saved.x)*room.X,tonumber(saved.y)*room.Y)
else
self.topLeft=Vector2.new((viewport.X-total*s)/2,(viewport.Y-self.height*s)/2)
end
end
local x=math.clamp(self.topLeft.X,8,math.max(8,viewport.X-total*s-8))
local y=math.clamp(self.topLeft.Y,8,math.max(8,viewport.Y-height*s-8))
self.topLeft=Vector2.new(x,y)
self.main.Position=UDim2.fromOffset(x,y)
self.dock.Size=UDim2.fromOffset(DOCK_WIDTH,self.dockHeight or DOCK_TOP)
self.dock.Position=UDim2.fromOffset(x+(self.width+DOCK_GAP)*s,y)
self.dock.Visible=self.main.Visible and not self.folded and#self.Tabs>0
self.grip.Visible=not self.folded
for _,tab in ipairs(self.Tabs)do for _,page in ipairs(tab.Pages)do page:_columns(self.width)end end
self:_updateLocation()
end
function Window:_saveMemory()
if self.cfg.SaveWindow==false or not self.alive then return end
local viewport=Util.viewport()
local s=self.scale.Scale
local room=Vector2.new(math.max(1,viewport.X-(self.width+DOCK_GAP+DOCK_WIDTH)*s),math.max(1,viewport.Y-self.height*s))
self.memory.window={
x=math.clamp(self.topLeft.X/room.X,0,1),y=math.clamp(self.topLeft.Y/room.Y,0,1),w=self.width,h=self.height,
}
if self._memoryQueued then return end
self._memoryQueued=true
task.delay(0.5,function()
self._memoryQueued=false
if self.alive then self.Config:WriteMemory(self.memory)end
end)
end
function Window:_beginDrag(input,move,finish)
self._drag={input=input,move=move,finish=finish}
end
function Window:_openPopup(frame,owner,onClose)
if self._popup and self._popup.frame~=frame then self:_closePopup()end
self._popup={frame=frame,owner=owner,close=onClose}
end
function Window:_closePopup()
local popup=self._popup
self._popup=nil
if popup then Util.safe(popup.close)end
end
function Window:_layoutDock()
for _,divider in ipairs(self.dockDividers)do divider:Destroy()end
self.dockDividers={}
local cursor=DOCK_TOP
for _,tab in ipairs(self.Tabs)do
if tab.Divider then
local divider=create("Frame",{Name="Divider",Position=UDim2.fromOffset(9,cursor+1),Size=UDim2.fromOffset(22,1),BorderSizePixel=0,ZIndex=42,Parent=self.dock})
Theme.bind(divider,"BackgroundColor3","line")
self.dockDividers[#self.dockDividers+1]=divider
cursor=cursor+8
end
tab.y=cursor
tab.button.Position=UDim2.fromOffset(5,cursor)
cursor=cursor+DOCK_STEP
end
self.dockHeight=cursor+8
end
function Window:_layoutBody()
local tab=self.current
local top=(tab and#tab.Pages>1)and 38 or 6
local bottom=self.hintBar.Visible and HINTS or 0
self.pages.Position=UDim2.fromOffset(0,top)
self.pages.Size=UDim2.new(1,0,1,-(top+bottom))
end
function Window:_titleWidth()
local layout=self.titleRow and self.titleRow:FindFirstChildOfClass("UIListLayout")
local ok,measured=pcall(function()return layout.AbsoluteContentSize.X end)
if ok and type(measured)=="number"and measured>0 then return measured/(self.scale and self.scale.Scale or 1)end
local width=Util.textWidth(self.Title,16,Enum.Font.GothamMedium)*1.05
if self.logo then width=width+24 end
if self.Version~=""then width=width+Util.textWidth(self.Version,9)+18 end
for _,child in ipairs(self.titleRow and self.titleRow:GetChildren()or{})do
if child.Name=="Tag"and child.Visible then
local text=child:FindFirstChild("Text")
width=width+(text and Util.textWidth(text.Text,8,Enum.Font.GothamBold)or 20)+18
end
end
return width
end
function Window:_updateLocation()
local tab=self.current
local room=self.width-(self.headerRight or 90)-16-self:_titleWidth()-16
local tabsWidth=0
for _,item in ipairs(self._headerButtons or{})do tabsWidth=tabsWidth+item.button.Size.X.Offset+6 end
local onHeaderTab=tab~=nil and tab.Header and self.cfg.HeaderTabs~=false
self.headerTabs.Visible=onHeaderTab and room>=tabsWidth
for _,item in ipairs(self._headerButtons or{})do
local selected=item.tab==tab
Theme.tweenTo(item.button,"TextColor3",selected and"heading"or"muted",0.12)
item.line.Visible=selected
end
if not tab then self.locationLabel.Text=""return end
local page=tab.current
self.locationLabel.Text=(page and#tab.Pages>1)and(tab.Title.." › "..page.Name)or tab.Title
self.locationLabel.Visible=room>=60 and not self.headerTabs.Visible
local share=math.floor(self.width*(self.monitorMode=="Header"and 0.25 or 0.45))
self.locationLabel.Size=UDim2.fromOffset(math.max(0,math.min(share,room)),20)
end
function Window:_addHeaderTab(tab)
local width=math.max(56,Util.textWidth(tab.Title,11,Enum.Font.GothamMedium)+14)
local button=create("TextButton",{
Name=tab.Title,Text=tab.Title,TextSize=11,Font=Enum.Font.GothamMedium,AutoButtonColor=false,
BackgroundTransparency=1,Size=UDim2.fromOffset(width,HEADER),LayoutOrder=#(self._headerButtons or{})+1,
Parent=self.headerTabs,
})
Theme.bind(button,"TextColor3","muted")
local line=create("Frame",{Name="SelectionLine",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),Size=UDim2.new(1,-14,0,2),BorderSizePixel=0,Visible=false,Parent=button})
Theme.bind(line,"BackgroundColor3","accent")
button.Activated:Connect(function()tab:Select()end)
self._headerButtons=self._headerButtons or{}
table.insert(self._headerButtons,{tab=tab,button=button,line=line})
end
function Window:_dockTip(text,y)
local s=self.scale.Scale
local dockX=self.dock.Position.X.Offset
local top=self.dock.Position.Y.Offset+(y+5)*s
self.tipText.Text=text
if dockX+(DOCK_WIDTH+8)*s+150>Util.viewport().X then
self.tip.AnchorPoint=Vector2.new(1,0)
self.tip.Position=UDim2.fromOffset(dockX-8,top)
else
self.tip.AnchorPoint=Vector2.new(0,0)
self.tip.Position=UDim2.fromOffset(dockX+(DOCK_WIDTH+8)*s,top)
end
self.tip.Visible=true
end
function Window:_tip(text)
local mouse=Services.UserInputService:GetMouseLocation()
local viewport=Util.viewport()
self.tipText.Text=tostring(text)
self.tip.AnchorPoint=Vector2.new(mouse.X>viewport.X-220 and 1 or 0,0)
self.tip.Position=UDim2.fromOffset(mouse.X+(mouse.X>viewport.X-220 and-12 or 14),math.min(mouse.Y+14,viewport.Y-30))
self.tip.Visible=true
local token={}
self._tipToken=token
task.delay(4,function()if self._tipToken==token and self.alive then self.tip.Visible=false end end)
end
function Window:_hideTip()self.tip.Visible=false end
function Window:_register(flag,element)
if self.flags[flag]then Util.log("[qustah-ui-lib] duplicate flag: "..tostring(flag))end
self.flags[flag]=element
task.defer(function()
if self.alive and self.flags[flag]==element then self.Config:_elementReady(flag,element)end
end)
end
function Window:_autoFlag(card,title)
local parts={}
local tab=card.page and card.page.tab
if tab and tab.Title then parts[#parts+1]=tab.Title end
if card.title then parts[#parts+1]=card.title end
parts[#parts+1]=tostring(title)
local flag=table.concat(parts,"."):gsub("[^%w_%.%- ]","")
local name,index=flag,2
while self.flags[name]or(self._autoNames and self._autoNames[name])do name=flag.." "..index index=index+1 end
self._autoNames=self._autoNames or{}
self._autoNames[name]=true
return name
end
function Window:_makeFlags()
local window=self
local function snapshot()
local values={}
for flag in pairs(window.flags)do values[flag]=window.Lib.Flags[flag]end
return values
end
self.Flags=setmetatable({},{
__index=function(_,flag)return window.Lib.Flags[flag]end,
__newindex=function(_,flag,value)window:SetFlag(flag,value)end,
__iter=function()return next,snapshot()end,
__pairs=function()return next,snapshot()end,
})
end
function Window:SetFlag(flag,value)
if flag==nil then return false end
local element=self.flags[flag]
if element and element.Set then
element:Set(value)
return true
end
self.Config.pending[flag]=value
self.Lib.Flags[flag]=value
self:_flagChanged(flag)
return false
end
function Window:GetFlag(flag)return self.Lib.Flags[flag]end
function Window:GetElement(flag)return self.flags[flag]end
function Window:_flagChanged()
local list=self._dependents
if not list or self._checkingDependents then return end
self._checkingDependents=true
for index=#list,1,-1 do
local ok,keep=pcall(list[index])
if ok and keep==false then table.remove(list,index)end
end
self._checkingDependents=false
end
function Window:_bind(element,key)
self.binds[element]=key
if not self._keyCheckQueued then
self._keyCheckQueued=true
task.defer(function()
self._keyCheckQueued=false
if self.alive~=false then self:_checkKeys()end
end)
end
end
function Window:_checkKeys()
local groups={}
for element,key in pairs(self.binds)do
if element.Row and not element.Row.Parent then
self.binds[element]=nil
elseif key~=nil and not(element.Chord and element.Chord[1]~=nil)
and not(type(element.Flag)=="string"and element.Flag:sub(1,2)=="__")then
groups[key]=groups[key]or{}
table.insert(groups[key],element)
end
end
local conflicts,seen={},{}
for key,list in pairs(groups)do
local menu=key==self.key
if#list>1 or menu then
local names={}
for _,element in ipairs(list)do names[#names+1]=tostring(element.Title or element.Type or"Key")end
if menu then names[#names+1]="Menu"end
table.sort(names)
conflicts[Util.keyName(key)]=names
for _,element in ipairs(list)do
local others={}
local own=tostring(element.Title or element.Type or"Key")
local skipped=false
for _,name in ipairs(names)do
if name==own and not skipped then skipped=true else others[#others+1]=name end
end
seen[element]=true
if element._setConflict then pcall(element._setConflict,element,others)end
end
end
end
for element in pairs(self.binds)do
if not seen[element]and element.KeyConflict and element._setConflict then pcall(element._setConflict,element,nil)end
end
local before=self._keyConflicts or{}
if self._keysSettled then
for keyName,names in pairs(conflicts)do
if not before[keyName]or#before[keyName]<#names then
self:Notify({Title="Key conflict",Content=keyName.." is used by "..table.concat(names," and "),Icon="triangle-alert",Color="warning",History=false})
end
end
end
self._keyConflicts=conflicts
end
function Window:GetKeyConflicts()return self._keyConflicts or{}end
function Window:Tab(cfg)
if type(cfg)=="string"then cfg={Title=cfg}end
local tab=Tab.new(self,cfg or{})
self.Tabs[#self.Tabs+1]=tab
if tab.Header then self:_addHeaderTab(tab)end
self:_layoutDock()
self:_layout()
if not self.current then tab:Select()end
return tab
end
function Window:SetVisible(visible)
self.visible=visible
self:_closePopup()
if not visible and self._dialog then self._dialog:Close()end
self:_hideTip()
self._token=(self._token or 0)+1
local token=self._token
if visible then
self.main.Visible=true
tween(self.main,0.14,{GroupTransparency=0})
tween(self.dock,0.14,{GroupTransparency=0})
self:_layout()
else
self._drag=nil
tween(self.main,0.12,{GroupTransparency=1})
tween(self.dock,0.12,{GroupTransparency=1})
task.delay(0.13,function()
if self.alive and token==self._token and not self.visible then
self.main.Visible=false
self.dock.Visible=false
end
end)
end
end
function Window:Toggle()self:SetVisible(not self.visible)end
function Window:SetUIScale(value)
value=math.clamp(tonumber(value)or 1,0.6,1.5)
self.uiScale=value
self:_closePopup()
self:_layout()
if self.memory then
self.memory.uiScale=value~=1 and value or nil
self:_saveMemory()
end
end
function Window:GetUIScale()return self.uiScale or 1 end
function Window:Minimize()
self.folded=not self.folded
self:_closePopup()
self.body.Visible=not self.folded
self.footer.Visible=not self.folded
self:_layout()
end
function Window:KeyHint(cfg)
cfg=cfg or{}
local right=cfg.Side=="Right"
local group=create("Frame",{
Name=tostring(cfg.Title or"Hint"),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,
Size=UDim2.fromOffset(0,26),LayoutOrder=#self.hints+1,Parent=right and self.hintRight or self.hintLeft,
})
Util.list(group,8,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
local badge=create("TextButton",{
Name="Key",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,Text="",TextSize=10,
Font=Enum.Font.GothamMedium,Size=UDim2.fromOffset(48,22),LayoutOrder=right and 3 or 1,Parent=group,
})
Theme.bind(badge,"TextColor3","text")
corner(badge,6)
local outline=stroke(badge,nil,0.25)
Theme.bind(outline,"Color","line")
local dot=label(group,"•",10,{Name="Dot",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),LayoutOrder=2,TextTruncate=Enum.TextTruncate.None})
Theme.bind(dot,"TextColor3","muted")
local caption=label(group,tostring(cfg.Title or""),9,{Name="Caption",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),LayoutOrder=right and 1 or 3,TextTruncate=Enum.TextTruncate.None})
Theme.bind(caption,"TextColor3","muted")
local window=self
local hint={Type="KeyHint",Title=cfg.Title,Row=group,Flag=cfg.Flag}
local function show(text)
badge.Text=text
badge.Size=UDim2.fromOffset(math.max(48,Util.textWidth(text,10,Enum.Font.GothamMedium)+18),22)
end
function hint:Set(key,silent)
key=Util.toKey(key)
if cfg.Menu and not key then key=window.key end
self.Value=key
show(Util.keyName(key))
if not cfg.Menu then window:_bind(self,key)end
if self.Flag then window.Lib.Flags[self.Flag]=key window:_flagChanged(self.Flag)end
if not silent then window:_safe(tostring(cfg.Title or"Key"),cfg.Callback,key)end
end
function hint:Get()return self.Value end
function hint:SetTitle(text)caption.Text=tostring(text)end
function hint:_onBind()window:_safe(tostring(cfg.Title or"Key"),cfg.Pressed,self.Value)end
function hint:_setConflict(others)
local on=others~=nil and#others>0
self.KeyConflict=on and others or nil
Theme.bind(badge,"TextColor3",on and"warning"or"text")
Theme.bind(outline,"Color",on and"warning"or"line")
end
function hint:_save()return self.Value and self.Value.Name or"None"end
function hint:_load(value)self:Set(value)end
badge.MouseEnter:Connect(function()Util.tween(outline,0.12,{Transparency=0.1})end)
badge.MouseLeave:Connect(function()Util.tween(outline,0.12,{Transparency=0.25})end)
badge.Activated:Connect(function()
show("...")
window._capture=function(key)
if key==Enum.KeyCode.Escape or(not cfg.Menu and key==window.key)then hint:Set(hint.Value,true)
elseif key==Enum.KeyCode.Backspace and not cfg.Menu then hint:Set(nil)
else hint:Set(key)end
end
end)
if cfg.Flag then self:_register(cfg.Flag,hint)end
self.hints[#self.hints+1]=hint
self.hintBar.Visible=true
self:_layoutBody()
hint:Set(cfg.Key,true)
return hint
end
function Window:BuildAll()
for _,tab in ipairs(self.Tabs)do if tab._build then tab:Build()end end
end
function Window:SetToggleKey(key)
key=Util.toKey(key)
if not key then
if self.menuHint then self.menuHint:Set(self.key,true)end
for _,listener in ipairs(self._menuListeners or{})do Util.safe(listener,self.key)end
return
end
self.key=key
task.defer(function()if self.alive then self:_checkKeys()end end)
if self.menuHint and self.menuHint.Value~=key then self.menuHint:Set(key,true)end
for _,listener in ipairs(self._menuListeners or{})do Util.safe(listener,key)end
end
function Window:SetFooter(text)self.footerText.Text=tostring(text or"")end
function Window:Notify(cfg)return self.Lib:Notify(cfg)end
function Window:Toast(cfg)return self.Lib:Toast(cfg)end
function Window:SelectTab(target)
for _,tab in ipairs(self.Tabs)do
if tab==target or tab.Title==target then tab:Select()return tab end
end
end
function Window:Destroy()
if not self.alive then return end
self.alive=false
self._drag,self._capture=nil,nil
self.maid:clean()
local env=(getgenv and getgenv())or _G
if env.__QustahUIWindows and env.__QustahUIWindows[self.Title]==self then env.__QustahUIWindows[self.Title]=nil end
for index,window in ipairs(self.Lib.Windows)do
if window==self then table.remove(self.Lib.Windows,index)break end
end
Util.safe(self.cfg.OnClose)
end
return Window
end
__modules["windowfx"]=function()
local Util=require("util")
local Theme=require("theme")
local create,corner,stroke,label,tween=Util.create,Util.corner,Util.stroke,Util.label,Util.tween
local function readableOn(color)
local function channel(c)return c<=0.03928 and c/12.92 or((c+0.055)/1.055)^2.4 end
local luminance=0.2126*channel(color.R)+0.7152*channel(color.G)+0.0722*channel(color.B)
return luminance>0.36 and Color3.fromRGB(18,18,22)or Color3.new(1,1,1)
end
return function(Window)
function Window:AddTag(text,opts)
if type(text)=="table"then opts,text=text,text.Text end
opts=opts or{}
self._tagCount=(self._tagCount or 0)+1
local tag=create("Frame",{
Name="Tag",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,16),BorderSizePixel=0,
LayoutOrder=10+self._tagCount,Parent=self.titleRow,
})
corner(tag,5)
Util.padding(tag,6,6,0,0)
local caption=label(tag,tostring(text or""),8,{
Name="Text",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromScale(0,1),Font=Enum.Font.GothamBold,
TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.None,
})
local edge=stroke(tag,nil,0.6)
local color,style=opts.Color or"accent",opts.Style=="Soft"and"Soft"or"Solid"
local function paint()
local fill=typeof(color)=="Color3"and color or Theme.get(color)
if style=="Soft"then
tag.BackgroundColor3,tag.BackgroundTransparency=fill,0.84
caption.TextColor3,edge.Color,edge.Transparency=fill,fill,0.55
else
tag.BackgroundColor3,tag.BackgroundTransparency=fill,0
caption.TextColor3,edge.Color,edge.Transparency=readableOn(fill),fill,1
end
end
paint()
local alive=true
Theme.onChange(function()if alive and tag.Parent then paint()end end)
local handle={Frame=tag}
function handle:SetText(value)caption.Text=tostring(value)end
function handle:SetColor(value)color=value or"accent"paint()end
function handle:SetVisible(visible)tag.Visible=visible~=false end
local window=self
function handle:Remove()
alive=false
tag:Destroy()
if window.alive then window:_updateLocation()end
end
task.defer(function()if window.alive then window:_updateLocation()end end)
return handle
end
function Window:SetLiveBackground(on)
self.liveBackground=on==true
if self._live then self._live.connection:Disconnect()self._live.frame:Destroy()self._live=nil end
if not self.liveBackground then return end
local frame=create("Frame",{Name="LiveBackground",Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=0,Active=false,Parent=self.main})
corner(frame,12)
Theme.bind(frame,"BackgroundColor3","accent")
local gradient=create("UIGradient",{
Transparency=NumberSequence.new({
NumberSequenceKeypoint.new(0,0.9),NumberSequenceKeypoint.new(0.35,0.985),
NumberSequenceKeypoint.new(0.7,0.95),NumberSequenceKeypoint.new(1,0.995),
}),
Parent=frame,
})
local started,last=os.clock(),0
local connection=Util.Services.RunService.Heartbeat:Connect(function()
local now=os.clock()
if now-last<1/24 or not self.main.Visible then return end
last=now
local t=now-started
gradient.Rotation=(t*9)%360
gradient.Offset=Vector2.new(math.sin(t*0.21)*0.25,math.cos(t*0.17)*0.25)
end)
self.maid:give(connection)
self._live={frame=frame,gradient=gradient,connection=connection}
end
function Window:SetAccentGlow(on)
self.accentGlow=on==true
if self._glowConnection then self._glowConnection:Disconnect()self._glowConnection=nil end
local edge=self.mainStroke
if not edge then return end
if not self.accentGlow then
Theme.bind(edge,"Color","edge")
edge.Transparency,edge.Thickness=0,1
return
end
Theme.bind(edge,"Color","accent")
edge.Thickness=1.5
local last=0
self._glowConnection=Util.Services.RunService.Heartbeat:Connect(function()
local now=os.clock()
if now-last<1/30 then return end
last=now
edge.Transparency=0.55+math.sin(now*2.1)*0.25
end)
self.maid:give(self._glowConnection)
end
function Window:SetBlur(on,size)
self.blur=on==true
if size then self.blurSize=math.clamp(tonumber(size)or 12,2,40)end
self:_applyBlur()
end
function Window:_applyBlur()
local want=self.blur and self.alive and self.visible
local effect=self._blurEffect
if effect and not effect.Parent then effect=nil self._blurEffect=nil end
if want and not effect then
pcall(function()
effect=Instance.new("BlurEffect")
effect.Name=Util.secure and Util.Services.HttpService:GenerateGUID(false)or"QustahUIBlur"
effect.Size=0
effect.Parent=Util.Services.Lighting
end)
self._blurEffect=effect
end
if not effect then return end
local target=want and(self.blurSize or 12)or 0
tween(effect,0.2,{Size=target})
if not want then
local token={}
self._blurToken=token
task.delay(0.22,function()
if self._blurToken==token and self._blurEffect==effect and not(self.blur and self.alive and self.visible)then
effect:Destroy()
self._blurEffect=nil
end
end)
else
self._blurToken=nil
end
end
local setVisible=Window.SetVisible
function Window:SetVisible(visible)
setVisible(self,visible)
if self.blur or self._blurEffect then self:_applyBlur()end
end
function Window:_state(key,value)
self._stateData=self._stateData or self.Config:ReadJSON("state")
if value~=nil then
self._stateData[key]=value
self.Config:WriteJSON("state",self._stateData)
end
return self._stateData[key]
end
function Window:ShowChangelog()
local log=self.cfg.Changelog
if type(log)~="table"then return nil end
local lines={}
for _,item in ipairs(log.Items or{})do lines[#lines+1]="•  "..tostring(item)end
if log.Content then table.insert(lines,1,tostring(log.Content)..(#lines>0 and"\n"or""))end
return self:Dialog({
Title=tostring(log.Title or("What's new"..(log.Version and(" in "..tostring(log.Version))or""))),
Icon=log.Icon or"sparkles",Content=table.concat(lines,"\n"),
Buttons={{Title=log.Button or"Got it",Style="Primary"}},
})
end
function Window:_changelog()
local log=self.cfg.Changelog
if type(log)~="table"then return end
local version=tostring(log.Version or self.Version or"")
if self:_state("changelogSeen")==version then return end
self:_state("changelogSeen",version)
task.delay(tonumber(log.Delay)or 1,function()
if self.alive and not self._dialog then self:ShowChangelog()end
end)
end
function Window:_welcome()
if self.cfg.Welcome==false or self.anonymous then return end
if self:_state("welcomeToast")==false then return end
local player=Util.Services.Players.LocalPlayer
if not player then return end
local id=tostring(player.UserId)
if self:_state("welcomed")==id then return end
self:_state("welcomed",id)
task.delay(0.6,function()
if not self.alive or self.anonymous then return end
self:Toast({Text="Signed in as <b>"..tostring(player.DisplayName or player.Name).."</b>",Image=Util.avatar(player.UserId),Duration=3.5})
end)
end
function Window:_buildFx()
local cfg=self.cfg
for _,item in ipairs(type(cfg.Tags)=="table"and cfg.Tags or{})do self:AddTag(item)end
local memory=self.memory or{}
local live=memory.liveBackground
if live==nil then live=cfg.LiveBackground==true end
if live then self:SetLiveBackground(true)end
local glow=memory.accentGlow
if glow==nil then glow=cfg.AccentGlow==true end
if glow then self:SetAccentGlow(true)end
local blur=memory.blur
if blur==nil then blur=cfg.Blur==true end
if blur then self:SetBlur(true,tonumber(cfg.BlurSize))end
self.maid:give(function()self.blur=false self:_applyBlur()end)
self:_welcome()
self:_changelog()
if self._autoTour then self:_autoTour()end
end
end
end
__modules["windowx"]=function()
local Util=require("util")
local Theme=require("theme")
local Icons=require("icons")
local create,corner,stroke=Util.create,Util.corner,Util.stroke
local SLOT=34
return function(Window)
function Window:_headerSlot()
self._slotX=(self._slotX or-74)-SLOT
self.headerRight=-self._slotX+16
if self.locationLabel then self.locationLabel.Position=UDim2.new(1,-self.headerRight,0,12)end
if self.headerTabs then self.headerTabs.Position=UDim2.new(1,-self.headerRight,0,0)end
return self._slotX
end
function Window:HeaderButton(cfg)
cfg=cfg or{}
local button=self._windowButton(tostring(cfg.Name or cfg.Tooltip or cfg.Icon or"Button"),self:_headerSlot(),false,true)
local icon=Icons.themed(button,cfg.Icon or"circle",15,"muted",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5)})
button.MouseEnter:Connect(function()
if icon then Theme.tweenTo(icon,"ImageColor3","heading",0.12)end
if cfg.Tooltip then self:_tip(cfg.Tooltip)end
end)
button.MouseLeave:Connect(function()
if icon then Theme.tweenTo(icon,"ImageColor3","muted",0.12)end
self:_hideTip()
end)
button.Activated:Connect(function()self:_safe(cfg.Tooltip or"Header button",cfg.Callback)end)
local handle={Button=button,Icon=icon}
function handle:SetIcon(name)if icon then Icons.Apply(icon,name)end end
function handle:SetVisible(visible)button.Visible=visible~=false end
return handle
end
function Window:SetFullscreen(on)
on=on==true
if on==(self.fullscreen==true)then return end
if on then
self._restore={width=self.width,height=self.height,topLeft=self.topLeft}
local viewport=Util.viewport()
self.width=math.max(self.minSize.X,math.floor(viewport.X-24-12-40-24))
self.height=math.max(self.minSize.Y,math.floor(viewport.Y-24))
self.topLeft=Vector2.new(12,12)
elseif self._restore then
self.width,self.height,self.topLeft=self._restore.width,self._restore.height,self._restore.topLeft
self._restore=nil
end
self.fullscreen=on
if self._fullscreenButton then self._fullscreenButton:SetIcon(on and"minimize-2"or"maximize-2")end
self:_layout()
end
function Window:ToggleFullscreen()self:SetFullscreen(not self.fullscreen)end
function Window:SetBackgroundImage(image,transparency)
if not self._background then
self._background=create("ImageLabel",{
Name="Background",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,
ImageTransparency=0.85,ZIndex=0,Parent=self.main,
})
corner(self._background,12)
end
local picture=self._background
picture.Image=""
if image==nil or image==""then picture.Visible=false return end
picture.Visible=true
if tonumber(transparency)then picture.ImageTransparency=math.clamp(tonumber(transparency),0,1)end
if not Icons.Apply(picture,image)then picture.Image=tostring(image)end
picture.ImageColor3=Color3.new(1,1,1)
end
function Window:SetBackgroundTransparency(value)
value=math.clamp(tonumber(value)or 0,0,0.9)
self.main.BackgroundTransparency=value
self.dock.BackgroundTransparency=math.max(0.03,value)
end
function Window:SetAnonymous(on)
self.anonymous=on==true
for _,listener in ipairs(self._anonListeners or{})do Util.safe(listener,self.anonymous)end
end
function Window:OnAnonymousChanged(callback)
self._anonListeners=self._anonListeners or{}
table.insert(self._anonListeners,callback)
callback(self.anonymous==true)
end
local layoutDock=Window._layoutDock
function Window:_layoutDock()
layoutDock(self)
if self._profile and self._profile.Visible then
local y=self.dockHeight-2
self._profileLine.Position=UDim2.fromOffset(9,y)
self._profile.Position=UDim2.fromOffset(5,y+7)
self.dockHeight=y+7+30+8
end
end
function Window:SetMouseUnlock(on)
self.unlockMouse=on~=false
self:_applyMouse()
end
function Window:_applyMouse()
local UserInputService=Util.Services.UserInputService
local free=self.alive and self.visible and self.unlockMouse
if self._modal then self._modal.Modal=free==true end
if free then
if self._savedMouseIcon==nil then self._savedMouseIcon=UserInputService.MouseIconEnabled end
UserInputService.MouseIconEnabled=true
elseif self._savedMouseIcon~=nil then
UserInputService.MouseIconEnabled=self._savedMouseIcon
self._savedMouseIcon=nil
end
end
local setVisible=Window.SetVisible
function Window:SetVisible(visible)
setVisible(self,visible)
self:_applyMouse()
end
function Window:_buildExtras()
local cfg=self.cfg
self._modal=create("TextButton",{Name="MouseUnlock",Text="",BackgroundTransparency=1,Size=UDim2.fromOffset(0,0),Modal=false,Parent=self.main})
self.unlockMouse=cfg.UnlockMouse~=false
self.maid:give(function()self.visible=false self:_applyMouse()end)
self:_applyMouse()
if cfg.FullscreenButton~=false then
self._fullscreenButton=self:HeaderButton({Name="Fullscreen",Icon="maximize-2",Tooltip="Fullscreen",Callback=function()self:ToggleFullscreen()end})
end
local header=self.main:FindFirstChild("Header")
local lastClick=0
if header then
self.maid:connect(header.InputBegan,function(input)
if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
local now=os.clock()
if now-lastClick<0.3 then lastClick=0 self:ToggleFullscreen()else lastClick=now end
end)
end
if cfg.Background then self:SetBackgroundImage(cfg.Background,cfg.BackgroundImageTransparency)end
if cfg.BackgroundTransparency then self:SetBackgroundTransparency(cfg.BackgroundTransparency)end
if cfg.Profile~=false then
local Players=Util.Services.Players
local player=Players.LocalPlayer
local line=create("Frame",{Name="ProfileLine",Size=UDim2.fromOffset(22,1),BorderSizePixel=0,ZIndex=42,Parent=self.dock})
Theme.bind(line,"BackgroundColor3","line")
local button=create("ImageButton",{
Name="Profile",AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromOffset(30,30),ZIndex=42,
ScaleType=Enum.ScaleType.Crop,Image="",Parent=self.dock,
})
Theme.bind(button,"BackgroundColor3","input")
corner(button,15)
local ring=stroke(button,nil,0.5,1.5)
Theme.bind(ring,"Color","buttonEdge")
local mask=Icons.themed(button,"hat-glasses",14,"muted",{Name="Anon",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=43,Visible=false})
local avatar=Util.avatar(player.UserId)
button.Image=avatar
self._profile,self._profileLine=button,line
self:OnAnonymousChanged(function(on)
button.Image=on and""or avatar
if mask then mask.Visible=on end
Theme.tweenTo(ring,"Color",on and"accent"or"buttonEdge",0.12)
end)
button.MouseEnter:Connect(function()
self:_dockTip(self.anonymous and"Anonymous · click to show"or(player.DisplayName.." · click to hide"),button.Position.Y.Offset)
end)
button.MouseLeave:Connect(function()self:_hideTip()end)
button.Activated:Connect(function()self:SetAnonymous(not self.anonymous)end)
self:_layoutDock()
self:_layout()
end
if cfg.Anonymous then self:SetAnonymous(true)end
end
end
end
return require("init")
