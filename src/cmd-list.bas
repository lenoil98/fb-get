'    fb-get - Package Manager for FreeBASIC
'    Copyright (C) 2013  Ebben Feagan
'
'    This program is free software; you can redistribute it and/or modify
'    it under the terms of the GNU General Public License as published by
'    the Free Software Foundation; either version 2 of the License, or
'    (at your option) any later version.
'
'    This program is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU General Public License for more details.
'
'    You should have received a copy of the GNU General Public License
'    along with this program; if not, write to the Free Software
'    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#include once "fb-get.bi"

declare sub printList( byval x as pnode ptr )

sub showList( byref opts as const string = "" )
    if opts = "-all" then
        if available <> NULL then
            print "Available packages:"
            printList(available->head)
        else
            FATAL("No available packages to list.")
        end if
    else if opts = "-updates" then
        if installed <> NULL then
            var curnode = installed->head
            while curnode <> NULL
                var ap = available->findItem(curnode->d._name)
                if ap <> NULL then
                    DEBUG("Package: " & curnode->d._name & " Remote: " & ap->version & " Local: " & curnode->d.version)
                    if ap->version > curnode->d.version then
                        print curnode->d._name & " " & ap->version & " (" & curnode->d.version & ")"
                    end if
                else
                    INFO("Package is only available locally: " & curnode->d._name)
                end if
                curnode = curnode->n
            wend
        end if
    else
        if installed <> NULL then
            print "Installed packages:"
            printList(installed->head)
        else
            FATAL("There are no installed packages to list.")
        end if
    end if
    print
end sub

sub printList( byval x as pnode ptr )
    var curnode = x
    while curnode <> NULL
        print curnode->d._name
        curnode = curnode->n
    wend
end sub
