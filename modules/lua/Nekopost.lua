function Register()

    module.Name = 'Nekopost'
    module.Language = 'Thai'

    module.Domains.Add('nekopost.net')
    module.Domains.Add('www.nekopost.net')

end

local function GetGalleryApiUrl()

    return '//api.osemocphoto.com/frontAPI/'

end

local function GetChapterApiUrl()

    return '//www.osemocphoto.com/'

end

local function GetGalleryId()

    return tostring(url):regex('\\/(?:comic|manga)\\/(\\d+)', 1)

end

local function GetChapterId()

    return tostring(url):regex('\\/(?:comic|manga)\\/\\d+\\/([\\d\\.]+)', 1)

end

local function GetGalleryJson()

    local endpoint = GetGalleryApiUrl() .. 'getProjectInfo/' .. GetGalleryId()
    local json = Json.New(http.Get(endpoint))

    return json

end

local function GetChapterJson()

    local galleryId = GetGalleryId()
    local chapterNumber = GetChapterId()
    local galleryJson = GetGalleryJson()

    -- Get the ID of the current chapter from the gallery JSON.

    local chapterId = galleryJson.SelectValue("listChapter[?(@.chapterNo == '" ..chapterNumber .. "')].chapterId")

    local endpoint = GetChapterApiUrl() .. FormatString('collectManga/{0}/{1}/{0}_{1}.json', galleryId, chapterId)
    local json = Json.New(http.Get(endpoint))
    
    return json

end

local function CleanTitle(title)

    return RegexReplace(tostring(title), '^.+?:', '')

end

function GetInfo()

    local json = GetGalleryJson()

    info.Title = json.SelectValue('projectInfo.projectName')
    info.Adult = json.SelectValue('projectInfo.flgMature') ~= 'N'
    info.Summary = json.SelectValue('projectInfo.info')
    info.DateReleased = json.SelectValue('projectInfo.releaseDate')
    info.Author = json.SelectValue('projectInfo.authorName')
    info.Artist = json.SelectValue('projectInfo.artistName')
    info.Tags = json.SelectValue('listCate[*].cateName')

    if(json.SelectValue('projectInfo.status') == '1') then
        info.Status = 'ongoing'
    else
        info.Status = 'completed'
    end

end

function GetChapters()

    local json = GetGalleryJson()

    for chapterNode in json.SelectTokens('listChapter[*]') do

        local chapterNumber = tostring(chapterNode['chapterNo'])
        local chapterName = tostring(chapterNode['chapterName'])

        local chapterTitle = 'Ch.' .. chapterNumber .. ' - ' .. chapterName
        local chapterUrl = url:trim('/') .. '/' .. chapterNumber
        
        chapters.Add(chapterUrl, chapterTitle)

    end

    chapters.Reverse()

end

function GetPages()

    local json = GetChapterJson()

    local galleryId = json.SelectValue('projectId')
    local chapterId = json.SelectValue('chapterId')

    local filenames = json.SelectValues('pageItem[*].fileName')

    -- Some chapters don't have a "fileName" property, and have a "pageName" property instead!
    -- BOTH of them are in use, so don't remove the former.

    if(isempty(filenames)) then
        filenames = json.SelectValues('pageItem[*].pageName')
    end

    for filename in filenames do

        local imageUrl = GetChapterApiUrl() .. FormatString('collectManga/{0}/{1}/{2}', galleryId, chapterId, filename)

        pages.Add(imageUrl)

    end

end
