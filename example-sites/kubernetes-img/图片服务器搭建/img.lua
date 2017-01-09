-- 检测路径是否目录
local function is_dir(sPath)
    if type(sPath) ~= "string" then
        return false
     end
    local response = os.execute("cd " .. sPath)
    if response == 0 then
        return true
    end
    return false
end
-- 文件是否存在
function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
         io.close(f)
         return true
    else
        return false
    end
end
-- 获取文件路径
function getFileDir(filename)
    return string.match(filename, "(.+)/[^/]*%.%w+$")
end
local gm_path = '/usr/local/graphicsmagick/bin/gm'
-- check image dir
if not is_dir(getFileDir(ngx.var.img_thumb_path)) then
    os.execute("mkdir -p " .. getFileDir(ngx.var.img_thumb_path))
end
--  等比缩放
--  gm convert /opt/www/hdimage/5243fbf2b2119313c4d3242166380cd790238d8b.jpg  -resize 600x600 +profile "*" /tmp/thumb/5243fbf2b2119313c4d3242166380cd790238d8b.jpg_600x600.jpg
if (file_exists(ngx.var.img_src_path)) then
    local cmd
    if (ngx.var.img_src_format=="gif" or ngx.var.img_src_format=="GIF") and ngx.var.img_thumb_fotmat ~="gif" then
      cmd = gm_path .. ' convert ' .. '\''..ngx.var.img_src_path..'[0]'..'\''
      cmd = cmd .." -resize "..ngx.var.img_width.."x" ..ngx.var.img_height..ngx.var.img_resize_type.." +profile \"*\" "..ngx.var.img_thumb_path
    else
      cmd = gm_path .. ' convert ' .. ngx.var.img_src_path
      cmd = cmd .." -resize "..ngx.var.img_width.."x" ..ngx.var.img_height..ngx.var.img_resize_type.." +profile \"*\" "..ngx.var.img_thumb_path
    end
    ngx.log(ngx.INFO, cmd);
    os.execute(cmd);
    ngx.exec(ngx.var.uri);
else
    ngx.exit(ngx.HTTP_NOT_FOUND);
end
