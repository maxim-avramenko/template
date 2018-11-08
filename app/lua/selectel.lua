-- check file in selectel cdn and download if exist
ngx.status = ngx.HTTP_NOT_FOUND
ngx.header["Content-type"] = "text/html"
ngx.say("Check file in selectel")
ngx.exit(0)
