local fileOpt = {}

local lfs = require"lfs"

--[[
-- params: fname is a full path directory that is relative 
-- to the root of /.
-- attension: the last char of fname shouldn't
-- be '/' .
--]]
function fileOpt.mkdir(fname)
    local wpath = CCFileUtils:sharedFileUtils():getWritablePath()
    local relative_name = string.sub(fname, #wpath+1, -1)
    --print("rname:", relative_name)
    fileOpt.mkRelativeDir(relative_name)
    if 1 then return end
    if not lfs.chdir(fname) then
        lfs.mkdir(fname)
    end
end

function fileOpt.split(str, delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

--[[
-- params: fname is a directory that is relative 
-- to the root of writable path.
-- attension: the last char of fname shouldn't
-- be '/' .
--]]
function fileOpt.mkRelativeDir(fname)
    local wpath = CCFileUtils:sharedFileUtils():getWritablePath()
    local arr = fileOpt.split(fname, "/")
    for ii=1,#arr do
        wpath = wpath .. arr[ii] .. "/"
        --print("wpath:", wpath)
        if not lfs.chdir(wpath) then
            lfs.mkdir(wpath)
        end
    end
end

function fileOpt.readFile(fname)
    local rfile = io.open(fname, "rb")
    if not rfile then
        print("open file failed:", fname)
        return nil
    end
    local content = rfile:read("*all")
    io.close(rfile)
    return content
end

function fileOpt.writeFile(data, fname)
    local pos = #fname
    while string.sub(fname, pos, pos) ~= "/" do
        pos = pos -1
        if pos <= 1 then
            print("path have no char / :", fname)
            return false
        end
    end
    local fpath = string.sub(fname, 1, pos)
    --print("fpath dir:",fpath)
    fileOpt.mkdir(fpath)
    if not lfs.chdir(fpath) then
        print("path not existed, create dir:", fpath)
        if not lfs.mkdir(fpath) then
            print("create " .. fpath .. " failed!")
            return false
        end
    end
    local wfile = io.open(fname, "wb")
    if not wfile then
        print("create file failed:", fname)
        return false
    end
    wfile:write(data)
    wfile:flush()
    io.close(wfile)

    return true
end

function fileOpt.cpfile(srcfile, dstfile)
    local content = fileOpt.readFile(srcfile)
    if content then
        local ret = fileOpt.writeFile(content, dstfile)
        return ret
    end
    return false
end

function fileOpt.rmfile(fname)
    local attr = lfs.attributes(fname)
    if attr == nil then return end
    if attr.mode == "file" then
        os.remove(fname)
        return true
    elseif attr.mode == "directory" then
        return fileOpt.rmdir(fname) 
    end
    return false 
end

function fileOpt.cpdir(src_dir, dst_dir)
    if not lfs.chdir(src_dir) then
        print("cp src_dir is not existed!")
        return
    end
    if not lfs.chdir(dst_dir) then
        fileOpt.mkdir(dst_dir)
    end
    for file in lfs.dir(src_dir) do
        if file ~= "." and file ~= ".." then
            local f = src_dir .. "/" .. file
            local attr = lfs.attributes(f)
            if attr.mode == "directory" then
                local tmp_dst_dir = dst_dir .. "/" .. file
                if not lfs.chdir(tmp_dst_dir) then
                    lfs.mkdir(tmp_dst_dir)
                end
                fileOpt.cpdir(f, tmp_dst_dir)
            else
                -- this is a file, copy it
                local dst_file = dst_dir .. "/" .. file
                if not fileOpt.cpfile(f, dst_file) then
                    print("cp file failed:", f, dst_file)
                end
            end
        end
    end
end

function fileOpt.rmdir(fname)
    if lfs.chdir(fname) then
        local function _rmdir(fname)
            local iter, dir_obj = lfs.dir(fname)
            while true do
                local dir = iter(dir_obj)
                if dir == nil then break end
                if dir ~= "." and dir ~= ".." then
                    local curDir = fname .. "/" .. dir
                    local attr = lfs.attributes(curDir)
                    if attr.mode == "directory" then
                        print("step into:", curDir)
                        _rmdir(curDir)
                    elseif attr.mode == "file" then
                        print("os.remove:", curDir)
                        os.remove(curDir)
                    end
                end
            end
            local succ, des = os.remove(fname)
            if des then print(des) end
            return succ
        end
        _rmdir(fname)
    end
    return true
end

function fileOpt.exists(path)
    return lfs.attributes(path, "mode") ~= nil
end

function fileOpt.isFile(path)
    return lfs.attributes(path, "mode") == "file"
end

function fileOpt.isDir(path)
    return lfs.attributes(path, "mode") == "directory"
end

return fileOpt
