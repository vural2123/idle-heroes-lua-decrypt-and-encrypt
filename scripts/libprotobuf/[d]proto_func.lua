pb = require "pb"

function varint_encoder(var)
    local  status, result = pcall(pb.varint_encoder, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function signed_varint_encoder(var)
    local  status, result = pcall(pb.signed_varint_encoder, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function read_tag(var)
    local  status, result = pcall(pb.read_tag, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function struct_pack(var)
    local  status, result = pcall(pb.struct_pack, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function struct_unpack(var)
    local  status, result = pcall(pb.struct_unpack, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function varint_decoder(var)
    local  status, result = pcall(pb.varint_decoder, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function signed_varint_decoder(var)
    local  status, result = pcall(pb.signed_varint_decoder, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function zig_zag_decode32(var)
    local  status, result = pcall(pb.zig_zag_decode32, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function zig_zag_encode32(var)
    local  status, result = pcall(pb.zig_zag_encode32, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function zig_zag_decode64(var)
    local  status, result = pcall(pb.zig_zag_decode64, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function zig_zag_encode64(var)
    local  status, result = pcall(pb.zig_zag_encode64, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end

function new_iostring(var)
    local  status, result = pcall(pb.new_iostring, var)
    if status then return result end
        if DEBUG > 1 then
        echoError("error:------can't decode")
    end
end