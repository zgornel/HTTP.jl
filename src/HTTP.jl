__precompile__(true)
module HTTP

#export Request, Response, FIFOBuffer



using MbedTLS
import MbedTLS.SSLContext
using Retry

const TLS = MbedTLS
const Headers = Vector{Pair{String, String}}

import Base.==

const DEBUG_LEVEL = 1

const DISABLE_CONNECTION_POOL = false

const DEBUG = false
const PARSING_DEBUG = false

if VERSION > v"0.7.0-DEV.2338"
    using Base64
end

if VERSION < v"0.7.0-DEV.2575"
    const Dates = Base.Dates
else
    import Dates
end

include("consts.jl")
include("utils.jl")
include("uri.jl")
#using .URIs
#include("fifobuffer.jl")
#using .FIFOBuffers
include("cookies.jl")
#using .Cookies
#include("multipart.jl")
#include("types.jl")

include("parser.jl")
#include("sniff.jl")


include("IOExtras.jl")
using .IOExtras

include("Bodies.jl")
#using .Bodies
include("Messages.jl")
#using .Messages

include("Connect.jl")
include("Connections.jl")
#using .Connections



include("SendRequest.jl")

#include("client.jl")
#include("handlers.jl")
#using .Handlers
#include("server.jl")
#using .Nitrogen

#include("precompile.jl")

function __init__()
#    global const client_module = module_parent(current_module())
#    global const DEFAULT_CLIENT = Client()
end

abstract type HTTPError <: Exception end

struct StatusError <: HTTPError
    status::Int16
    response::Messages.Response
end
StatusError(r::Messages.Response) = StatusError(r.status, r)

include("RetryRequest.jl")
include("CookieRequest.jl")

end # module
#=
try
    HTTP.parse(HTTP.Response, "HTTP/1.1 200 OK\r\n\r\n")
    HTTP.parse(HTTP.Request, "GET / HTTP/1.1\r\n\r\n")
    HTTP.get(HTTP.Client(nothing), "www.google.com")
end
=#
