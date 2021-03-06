local render = {};

--#region Load libs
local rojo = game:GetService("ReplicatedStorage"):WaitForChild("rojo")
local MaterialUI if false then MaterialUI = require("MaterialUI.init"); end
MaterialUI = require(rojo:WaitForChild("MaterialUI"));
local EDrow = MaterialUI.Create;
local try if false then AdvancedTween = require("try"); end
try = require(script.Parent.try);
local PlayerUtil if false then AdvancedTween = require("PlayerUtil"); end
PlayerUtil = require(script.Parent.PlayerUtil);
--#endregion
--#region Get RBX Items
local UDim2 = UDim2;
local Enum = Enum;
local Vector2 = Vector2;
--#endregion

--#region Settings / Global
local GlobalFont = Enum.Font.Gotham;
local GlobalBoldFont = Enum.Font.GothamBold;
local LocalPlayer = game:GetService("Players").LocalPlayer or {Name = nil,UserId = nil;};
--#endregion

--#region EDrow 대충 설명
-- EDrow 함수는 인자로 3개 받음(보통의 경우)
-- 1번째는 클래스명, 2번째는 프로퍼티들, 3번째는 자식 개체 담은 테이블
-- 1번째는 함수나 테이블로도 쓰일 수 있고 Button 이나 CheckBox 같이 커스텀 클래스도 존재함
-- 2번째 프로퍼티 테이블에 WhenCreated 에 함수 넣으면 해당 개체가 만들어질때 self 넘겨줌
-- 3번째는 {Name = Child;} 로 이루워짐
-- 이걸 스텍 쌓을수도 있음
-- EDrow("Frame",{
--     BackgroundTransparency = 1;   
-- },{
--     EDrow("Frame",{
--         BackgroundTransparency = 1;   
--     },{
--         ...
--     });
-- });
-- 자세한건 MaterialUI 에 Create 를 참고 바람...
--#endregion

local Connection = {}; -- 나중에 이걸로 바인딩 지움
local LastRender = {}; -- 나중에 이걸로 UI 지움
local LastPlayers = {};

---@param PClass userdata Player Instance
---@param DisplayIndex integer Display Order
---@param Leaderstats table Leaderstats data
---@param GetPlayerIcon function GetPlayerIcon function (nil = default)
---@return userdata Instance RUI-Render Object
---@see 플레이어 리스트 아이템 하나 그리기
function render.PlayerItem(PlayerClass,DisplayIndex,Leaderstats,GetPlayerIcon,LeaderstatsChanged)
    local PlayerIcon = GetPlayerIcon and GetPlayerIcon(PlayerClass) or nil;
    local PlayerIconIsClass = type(PlayerIcon) ~= "nil" and type(PlayerIcon) ~= "string";

    local Store = {};
    return EDrow("ImageLabel",{
        BackgroundTransparency = 1;
        Size = UDim2.new(1,0,0,28);
        LayoutOrder = DisplayIndex or 1;
        ImageColor3 = Color3.fromRGB(0,0,0);
        ImageTransparency = 0.5;
        WhenCreated = function (this)
            MaterialUI:SetRound(this,50);
        end;
    },{
        -- 텍스트 렌더링
        PlayerNameLabel = EDrow("TextLabel",{
            Text = PlayerClass.Name;
            TextSize = 14;
            -- 나면 굵은 글씨채 적용
            Font = (PlayerClass.ClassName == "Player" and LocalPlayer.UserId == PlayerClass.UserId) and GlobalBoldFont or GlobalFont;
            TextColor3 = Color3.fromRGB(255,255,255);
            BackgroundTransparency = 1;
            Size = UDim2.new(1,-32,1,0);
            Position = UDim2.fromOffset(32,0);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextTruncate = Enum.TextTruncate.AtEnd;
            ClipsDescendants = true;
            WhenCreated = function (this)
                Store.NameText = this;
            end;
        });
        -- 썸네일 렌더링 (캐릭터 프필 가져옴)
        PlayerImage = PlayerIconIsClass and PlayerIcon or EDrow("ImageLabel",{
            Image = PlayerIcon or try(PlayerUtil.GetPlayerIcon,PlayerClass.UserId):err(function (errinfo)
                warn("an error occurred on loading player image");
                warn(errinfo);
                return ""; -- error 잡히면 일단 이미지 비움
            end):getreturn();
            Size = UDim2.new(1,0,1,0);
            SizeConstraint = Enum.SizeConstraint.RelativeYY;
            Position = UDim2.new(0,0,0,0);
            BackgroundTransparency = 1;
        },{
            -- 둥글게 적용
            EDrow("UICorner",{
                CornerRadius = UDim.new(1,0);
            });
        });
        -- 리더보드 렌더링
        Leaderstats = EDrow("Frame",{
            Size = UDim2.fromScale(1,1);
            BackgroundTransparency = 1;
            WhenCreated = function (this)
                if not Leaderstats then
                    return nil;
                end
                
                -- 리더스텟을 그림
                local TotalLeaderstatsSize = 0;
                for Index,Stats in pairs(Leaderstats) do
                    TotalLeaderstatsSize = TotalLeaderstatsSize + (Stats.Size or 50);
                    local Label = EDrow("TextLabel",{
                        Size = UDim2.new(0,Stats.Size or 50,1,0);
                        LayoutOrder = Index;
                        Parent = this;
                        Font = GlobalFont;
                        TextSize = 11;
                        Text = "";
                        ClipsDescendants = true;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BackgroundTransparency = 1;
                        TextColor3 = Color3.fromRGB(255,255,255);
                    },{
                        -- 경계선
                        Div = EDrow("Frame",{
                            BackgroundColor3 = Color3.fromRGB(190,190,190);
                            BackgroundTransparency = 0.4;
                            Size = UDim2.new(0,1,0.7,0);
                            AnchorPoint = Vector2.new(0,0.5);
                            Position = UDim2.fromScale(0,0.5);
                        });
                    });

                    -- 값 바뀜
                    Connection[#Connection+1] = Stats.BindToChanged(PlayerClass,function ()
                        Label.Text = Stats.GetValue(PlayerClass);
                        LeaderstatsChanged()
                    end);
                    Label.Text = Stats.GetValue(PlayerClass);
                end
                
                -- 이름 크기지정
                Store.NameText.Size = UDim2.new(1,-Store.NameText.Position.X.Offset - TotalLeaderstatsSize,1,0);

                return true;
            end;
        },{
            ListLayOut = EDrow("UIListLayout",{
                SortOrder = Enum.SortOrder.LayoutOrder;
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
            });
        });
    });
end

---@see 맨 위에 Name | Leaderstats 같이 라벨 쓰는 함수
function render.Header(Leaderstats)
    return EDrow("Frame",{
        BackgroundTransparency = 1;
        Size = UDim2.new(1,0,0,20);
        --Size = UDim2.new(0,170,0,28); --<< Layout;
        --Position = << Layout;
        LayoutOrder = -255;
    },{
        -- 분리선
        Div = EDrow("Frame",{
            Size = UDim2.new(1,-18,0,1);
            Position = UDim2.new(0.5,0,1,-1);
            AnchorPoint = Vector2.new(0.5,0);
            BackgroundColor3 = Color3.fromRGB(150,150,150);
            BackgroundTransparency = 0.1;
        });
        -- 텍스트 렌더링
        PlayerNameLabel = EDrow("TextLabel",{
            Text = "Name";
            TextSize = 13;
            Font = GlobalFont;
            TextColor3 = Color3.fromRGB(0,0,0);
            BackgroundTransparency = 1;
            Size = UDim2.fromScale(1,1);
            Position = UDim2.fromOffset(8,0);
            TextXAlignment = Enum.TextXAlignment.Left;
        });
        -- 리더보드 렌더링
        Leaderstats = EDrow("Frame",{
            Size = UDim2.fromScale(1,1);
            BackgroundTransparency = 1;
            WhenCreated = function (this)
                if not Leaderstats then
                    return nil;
                end
                
                -- 리더스텟을 그림
                for Index,Stats in pairs(Leaderstats) do
                    local Label = EDrow("TextLabel",{
                        Size = UDim2.new(0,Stats.Size or 50,1,0);
                        LayoutOrder = Index;
                        Text = Stats.Name;
                        Font = GlobalFont;
                        TextSize = 13;
                        TextColor3 = Color3.fromRGB(0,0,0);
                        BackgroundTransparency = 1;
                        Parent = this;
                    });
                end
            end;
        },{
            ListLayOut = EDrow("UIListLayout",{
                SortOrder = Enum.SortOrder.LayoutOrder;
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
            });
        });
    });
end

---@see 제정렬, 리더스탯을 순서로 하면 이게 필요해짐
function render.Resort(Data)
    local Sort = Data.Sort;
    if not Sort then
        return nil;
    end

    LastPlayers = Sort(LastPlayers);
    for DisplayIndex,PlayerClass in pairs(LastPlayers) do
        local ListItem = LastRender[PlayerClass];
        if ListItem then
            ListItem.LayoutOrder = DisplayIndex;
        end
    end
    return true;
end

--@param PData table Player Data array
--@return table Array RUI-Render Object Array
--@see render player list
function render:render(Data)
    -- 렌더 초기화
    local OldConnection = Connection;
    Connection = {};

    local PlayerData = Data.Players; -- 플레이어가 담긴 테이블
    local Leaderstats = Data.Leaderstats; -- 플레이어에 대해서 리더스텟 그리기
    local Sort = Data.Sort; -- 플레이어를 정렬하는 함수
    local ResortOnLeaderstatsChanged = Data.ResortOnLeaderstatsChanged; -- 리더스텟 바뀔때 리솔트 할지 여부
    local GetPlayerIcon = Data.GetPlayerIcon; -- 플레이어 아이콘 가져오는 함수
    local EditItem = Data.EditItem; -- 플레이어 아이템 편집 함수(테마라던가)
    local EditHeader = Data.EditHeader; -- 헤더 부분 편집 함수(글자 색깔이라던가)
    LastPlayers = PlayerData;

    -- 정렬하는 함수 있으면 정렬
    if Sort then
        PlayerData = Sort(PlayerData);
    end

    -- 리더스텟 바뀜 (정렬용)
    local function LeaderstatsChanged()
        if ResortOnLeaderstatsChanged and Sort then
            self.Resort(Data);
        end
    end

    -- 그리기
    local list = {};
    local header = self.Header(Leaderstats); -- 헤더 그리기
    if EditHeader then
        EditHeader(header,Leaderstats);
    end
    list["Header"] = header;
    for DisplayIndex,PlayerClass in pairs(PlayerData) do
        local new = self.PlayerItem(PlayerClass,DisplayIndex,Leaderstats,GetPlayerIcon,LeaderstatsChanged);
        if EditItem then
            EditItem(new,PlayerClass);
        end
        list[PlayerClass] = new;
    end

    -- 이전 커넥션 제거 (리더스텟 바뀜 트래킹이라던가)
    for Index,Unbind in pairs(OldConnection) do
        if Unbind then
            Unbind();
        end
        Connection[Index] = nil;
    end
    -- 이전 UI 제거
    for _,Item in pairs(LastRender) do
        Item:Destroy();
    end

    LastRender = list; -- 나중에 지울 수 있게 만들기
    return list;
end

return render;