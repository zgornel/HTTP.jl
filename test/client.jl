@testset "HTTP.Client" begin

@testset "HTTP.Connection" begin
    conn = HTTP.Connection(IOBuffer())
    @test conn.state == HTTP.Busy
    HTTP.idle!(conn)
    @test conn.state == HTTP.Idle
    HTTP.busy!(conn)
    @test conn.state == HTTP.Busy
    HTTP.dead!(conn)
    @test conn.state == HTTP.Dead
    HTTP.idle!(conn)
    @test conn.state == HTTP.Dead
    HTTP.busy!(conn)
    @test conn.state == HTTP.Dead
end

#TODO:
 # make sure we send request cookies in write(tcp, request)
 # handle other body types for request sending, Vector{UInt8}, String, IO, FIFOBuffer
 # @code_warntype functions to find anything fishy
 # benchmark vs. Requests and python requests?
 # docs
 # spec tests
 # cleanup cookies.jl file to get server-side stuff done
 ####### v0.1 LINE
 # proxy stuff
 # multi-part encoded files
 # response caching?
 # digest authentication
 # auto-gzip response

for sch in ("http", "https")

    @test HTTP.get("$sch://httpbin.org/ip").status == 200
    @test HTTP.head("$sch://httpbin.org/ip").status == 200
    @test HTTP.options("$sch://httpbin.org/ip").status == 200
    @test HTTP.post("$sch://httpbin.org/ip").status == 405
    @test HTTP.post("$sch://httpbin.org/post").status == 200
    @test HTTP.put("$sch://httpbin.org/put").status == 200
    @test HTTP.delete("$sch://httpbin.org/delete").status == 200
    @test HTTP.patch("$sch://httpbin.org/patch").status == 200

    @test HTTP.get("$sch://httpbin.org/encoding/utf8").status == 200

    r = HTTP.get("$sch://httpbin.org/cookies")
    @test String(readavailable(r.body)) == "{\n  \"cookies\": {}\n"
    @test !haskey(HTTP.DEFAULT_CLIENT.cookies, "httpbin.org")
    r = HTTP.get("$sch://httpbin.org/cookies/set?hey=sailor")
    @test r.status == 200
    @test String(readavailable(r.body)) == "{\n  \"cookies\": {\n    \"hey\": \"sailor\"\n  }\n"
    r = HTTP.get("$sch://httpbin.org/cookies/delete?hey")
    @test String(readavailable(r.body)) == "{\n  \"cookies\": {\n    \"hey\": \"\"\n  }\n"

    # stream

    # body posting: Vector{UInt8}, String, IOStream, IOBuffer, FIFOBuffer
    r = HTTP.post("$sch://httpbin.org/post"; body="hey")
    @test r.status == 200
    r = HTTP.post("$sch://httpbin.org/post"; body="hey", stream=true)
    @test r.status == 200
    r = HTTP.get("$sch://httpbin.org/stream/100")
    @test r.status == 200
    totallen = length(r.body) # number of bytes to expect
    bytes = readavailable(r.body)
    begin
        r = HTTP.get("$sch://httpbin.org/stream/100"; stream=true)
        @test r.status == 200
        len = length(r.body)
        @test len < totallen
        HTTP.@timeout 15.0 begin
            while !eof(r.body)
                b = readavailable(r.body)
                println("lenght = $(length(b))....")
            end
        end throw(HTTP.TimeoutException(15.0))
    end

    # redirects
    r = HTTP.get("$sch://httpbin.org/redirect/1")
    @test r.status == 200
    @test length(r.history) == 1
    @test_throws HTTP.RedirectException HTTP.get("$sch://httpbin.org/redirect/6")
    @test HTTP.get("$sch://httpbin.org/relative-redirect/1").status == 200
    @test HTTP.get("$sch://httpbin.org/absolute-redirect/1").status == 200
    @test HTTP.get("$sch://httpbin.org/redirect-to?url=http%3A%2F%2Fexample.com").status == 200

    @test HTTP.post("$sch://httpbin.org/post"; body="√").status == 200
    @test HTTP.get("$sch://user:pwd@httpbin.org/basic-auth/user/pwd").status == 200
    @test HTTP.get("$sch://user:pwd@httpbin.org/hidden-basic-auth/user/pwd").status == 200

    @test_throws HTTP.TimeoutException HTTP.get("$sch://httpbin.org/delay/3"; readtimeout=1.0)
end

end # @testset "HTTP.Client"