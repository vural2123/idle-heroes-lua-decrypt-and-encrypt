local generator = {}

require "protocol.dr2_comm_pb"
require "protocol.dr2_login_pb"
require "protocol.dr2_logic_pb"

local _base_module_name = "dr2_comm_pb"

local modules = {}
modules[_base_module_name] = dr2_comm_pb
modules["dr2_login_pb"] = dr2_login_pb
modules["dr2_logic_pb"] = dr2_logic_pb

function generator.genEchoData(params)
    local _obj = dr2_login_pb.pbreq_echo()
    _obj.echo = params.echo
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

function generator.genRegData(params)
    local _obj = dr2_login_pb.pbreq_reg()
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

function generator.genSaltData(params)
    local _obj = dr2_login_pb.pbreq_salt()
    _obj.account = params.account
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

function generator.genLoginData(params)
    local _obj = dr2_login_pb.pbreq_login()
    _obj.checksum = params.checksum
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

function generator.genAuthData(params)
    --local _obj = dr2_logic_pb.pbreq_auth()
    --_obj.session = params.session
    --if params.uid then
    --    _obj.uid = params.uid
    --end
    --local _proto_data = _obj:SerializeToString()
    --return _proto_data
    params.module_name = "dr2_logic_pb"
    params.class_name = "pbreq_auth"
    return generator.genProtoData(params)
end

function generator.genSyncData(params)
    local _obj = dr2_logic_pb.pbreq_sync()
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

function generator.genGachaData(params)
    --local _obj = dr2_logic_pb.pbreq_gacha()
    --_obj.type = params.type
    --_obj.free = params.free
    --if params.item then
    --    _obj.item.id = params.item.id
    --    _obj.item.num = params.item.num
    --end
    --local _proto_data = _obj:SerializeToString()
    --return _proto_data
    params.module_name = "dr2_logic_pb"
    params.class_name = "pbreq_gacha"
    return generator.genProtoData(params)
end

function generator.genOpMailData(params)
    local _obj = dr2_logic_pb.pbreq_op_mail()
    if params.reads then
        for ii=1,#params.reads do
            _obj.reads:append(params.reads[ii])
        end
    end
    if params.deletes then
        for ii=1,#params.deletes do
            _obj.deletes:append(params.deletes[ii])
        end
    end
    if params.affix then
        _obj.affix = params.affix
    end
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

local function objAssign(module_name, class_name, obj, params)
    local fields = modules[module_name][string.upper(class_name)].fields
    for ii=1,#fields do
        if type(fields[ii].default_value) == "table" and fields[ii].message_type then
            if params[fields[ii].name] then
                local _module_name = _base_module_name
                local _class_name = fields[ii].message_type.name
                for jj=1,#params[fields[ii].name] do
                    local tmp_obj = obj[fields[ii].name]:add(modules[_module_name][_class_name]())
                    objAssign(_module_name, _class_name, tmp_obj, params[fields[ii].name][jj])
                end
            end
        elseif type(fields[ii].default_value) == "table" then
            if params[fields[ii].name] then
                local _module_name = _base_module_name
                for jj=1,#params[fields[ii].name] do
                    obj[fields[ii].name]:append(params[fields[ii].name][jj])
                end
            end
        elseif fields[ii].message_type then
            if params[fields[ii].name] then
                local _module_name = _base_module_name
                local _class_name = fields[ii].message_type.name
                objAssign(_module_name, _class_name, obj[fields[ii].name], params[fields[ii].name])
            end
        else
            if params[fields[ii].name] then
                obj[fields[ii].name] = params[fields[ii].name]
            end
        end
    end
end

function generator.genProtoData(params)
    local module_name = params.module_name
    local class_name = params.class_name
    local _obj = modules[module_name][class_name]()
    objAssign(module_name, class_name, _obj, params)
    local _proto_data = _obj:SerializeToString()
    return _proto_data
end

return generator
