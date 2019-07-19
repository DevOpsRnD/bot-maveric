
ldap = require('ldapjs')

class LDAP

    constructor: (@robot) ->
        creds = url: process.env.HUBOT_LDAP_URL
        @client = ldap.createClient(creds)
        @authenticate
    
    authenticate: ->
        @client.bind process.env.HUBOT_LDAP_USERNAME, process.env.HUBOT_LDAP_PASSWORD, (err) ->
            if err?
                console.log 'LDAP not authenticated'
                console.log 'err', err.message
                cb false
            else
                console.log 'LDAP authenticated'
                cb true

    listRoleMembers: (role, cb) ->
        memberList = []
        if @client
            opts = { scope: 'sub', attributes: ['dn', 'sn', 'cn', 'mail'] }
            @client.search "ou=#{role},dc=example,dc=com", opts, (err, search) ->
                if err?
                    console.log "Error occured while fetching members for role #{role}"
                    console.log 'err ', err.message
                    cb memberList
                else
                    search.on "searchEntry", (entry) ->
                        memberList.push entry.object
                        # cb memberList
                    search.on "end", (err) ->
                        if !memberList.length
                            console.log 'Members not Found'
                        cb memberList
        else
            console.log 'client not found'

    ### hasUserRole: (user, role, cb) ->
        isUserExist = false
        options =
            filter: "(mail=#{user})"
            scope: 'sub'

        console.log user + '--' + role

        @client.bind ldap_username, ldap_password, (err) ->
            if err?
                console.log 'not authenticated'
                console.log 'err', err.message
            else
                @client.search "ou=#{role},dc=example,dc=com", options, (err, search) ->
                    if err?
                        console.log 'data not found'
                        console.log 'err', err.message
                        return false
                    else
                        search.on "searchEntry", (entry) ->
                            isUserExist = true
                            user = entry.object
                            console.log user
                            cb true 
                        search.on "end", (err) ->
                            if !isUserExist
                                cb false
                            return
                    return ###

module.exports = LDAP
