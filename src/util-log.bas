'    freebasic logging
'Copyright (c) 2013, Ebben Feagan <sir_mud@users.sf.net>
'All rights reserved.
'
'Redistribution and use in source and binary forms, with or without
'modification, are permitted provided that the following conditions are met:
'    * Redistributions of source code must retain the above copyright
'      notice, this list of conditions and the following disclaimer.
'    * Redistributions in binary form must reproduce the above copyright
'      notice, this list of conditions and the following disclaimer in the
'      documentation and/or other materials provided with the distribution.
'    * Neither the name of the Ebben Feagan nor the
'      names of its contributors may be used to endorse or promote products
'      derived from this software without specific prior written permission.
'
'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
'ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
'WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
'DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
'DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
'(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
'LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
'ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
'(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
'SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include once "vbcompat.bi"
#include once "util.bi"
#include once "crt/string.bi"

type _log_channel
    public:
    method as l_m
    _data as any ptr
    _fdata as any ptr
    _fdata_free as any ptr
    level as LOGLEVEL
    declare constructor()
    declare destructor()
end type

constructor _log_channel
    method = LOG_PRINT
    level = _INFO
end constructor

destructor _log_channel
    if _fdata <> 0 then
        cast(custom_data_free,_fdata_free)(_fdata)
    end if
end destructor

dim shared __log_channel as _log_channel ptr
dim shared __log_nc as uinteger

private function lstr( byval l as LOGLEVEL ) as string
    select case l
    case _DEBUG
        return "DEBUG"
    case _INFO
        return "INFO"
    case _WARN
        return "WARN"
    case _FATAL
        return "FATAL"
    end select
    return "LLAMA"
end function

sub set_log_level( byval l as LOGLEVEL )
        __log_channel[0].level = l
end sub

sub set_log_level( byval channel as uinteger, byval l as LOGLEVEL )

    if channel < __log_nc orelse channel = 0 then
    __log_channel[channel].level = l
    end if

end sub

sub set_log_method overload ( byval m as l_m, byval d as any ptr = 0, byval fd as any ptr = 0, byval fdf as any ptr = 0 )
    set_log_method(0,m,d,fd,fdf)
end sub

sub set_log_method( byval channel as uinteger, byval m as l_m, byval d as any ptr = 0, byval fd as any ptr = 0, byval fdf as any ptr = 0 )

    if channel < __log_nc orelse channel = 0 then
    __log_channel[channel].method = m
    __log_channel[channel]._data = d
    __log_channel[channel]._fdata = fd
    __log_channel[channel]._fdata_free = fdf
    end if

end sub

sub __init_log () constructor
    __log_nc = 1
    __log_channel = new _log_channel[__log_nc]
end sub

sub __destroy_log () destructor
    if __log_channel <> NULL then delete[] __log_channel
    __log_nc = 0
end sub

function set_num_channels( byval c as uinteger ) as integer
    if c = __log_nc then return 0
    var newp = new _log_channel[c]
    if newp <> NULL then
        memcpy(newp,__log_channel,iif(c>__log_nc,__log_nc,c))
        var oldp = __log_channel
        __log_channel = newp
        __log_nc = c
        delete[] oldp
        return 0
    end if
    return not 0
end function

function iso_datetime( byval t as double ) as string

    return format(t,"yyyy-mm-ddThh:mm:ss")

end function

sub __log( byval lvl as LOGLEVEL, _
            byref _msg_ as const string, _
            byref _file_ as const string, _
            byval _line_number_ as integer, _
            byval channel as uinteger = 0 _
            )

    if channel < __log_nc orelse channel = 0 then

    if lvl < __log_channel[channel].level then return

    select case __log_channel[channel].method
    case LOG_NULL
        return
    case LOG_PRINT
        print lstr(lvl) & ": " & _msg_
    case LOG_FILE
        var fname_ = cast(zstring ptr,__log_channel[channel]._data)
        var fname = ""
        if fname_ <> 0  then
            fname = *fname_
        else
            fname = command(0) & ".log"
        end if
        var isodate = ""

        var ff = freefile
        open fname for append access write as #ff
        print #ff, iso_datetime(now) & " " & lstr(lvl) & " " & _msg_ & " -> " & _file_ & ":" & _line_number_
        close #ff
    case LOG_CUSTOM
        cast(log_custom_sub,__log_channel[channel]._data)(lvl,_msg_,_file_,_line_number_,__log_channel[channel]._fdata)
    end select

    end if

end sub

#ifdef __FB_MAIN__

    sub my_custom_log( byval l as loglevel, byref m as const string, byref f as const string, byval l_ as integer, byval fd as any ptr )
        print m
    end sub

    enum MyChannels
        MAIN_C = 0
        FILE_C
        CUST_C
    end enum

    set_num_channels(3) 'gives us channel 0, 1 and 2
    set_log_method(FILE_C,LOG_FILE) 'direct log channel 2 output to a file, should be writable by the process or will silently fail
    set_log_level(FILE_C,_WARN) 'The default level is INFO, only print this level and above
    set_log_method(CUST_C,LOG_CUSTOM,@my_custom_log) 'change it up a bit

    INFO("This is a test log message.") 'print this one
    DEBUG("This is a test debug message.") 'debug not printed by default
    INFOto(FILE_C,"This is also a test log message.") 'not printed
    WARNto(FILE_C,"Only one entry should be written to the log.") 'printed
    WARNto(CUST_C,"Whoa dude, we can do anything with this!") 'whoa!

#endif
