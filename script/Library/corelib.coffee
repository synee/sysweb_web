$ ()->

#    keymap
    (->
        keyStack = []
        q = {
            "0": "\\", 8: "backspace", 9: "tab", 12: "num", 13: "enter", 16: "shift", 17: "ctrl", 18: "alt", 19: "pause", 20: "caps",
            27: "esc", 32: "space", 33: "pageup", 34: "pagedown", 35: "end", 36: "home", 37: "left", 38: "up", 39: "right", 40: "down",
            44: "print", 45: "insert", 46: "delete",
            48: "0", 49: "1", 50: "2", 51: "3", 52: "4", 53: "5", 54: "6", 55: "7", 56: "8", 57: "9",
            65: "a", 66: "b", 67: "c", 68: "d", 69: "e", 70: "f", 71: "g", 72: "h", 73: "i", 74: "j", 75: "k", 76: "l", 77: "m",
            78: "n", 79: "o", 80: "p", 81: "q", 82: "r", 83: "s", 84: "t", 85: "u", 86: "v", 87: "w", 88: "x", 89: "y", 90: "z",
            91: "cmd", 92: "cmd", 93: "cmd",
            96: "num_0", 97: "num_1", 98: "num_2", 99: "num_3", 100: "num_4", 101: "num_5", 102: "num_6", 103: "num_7", 104: "num_8", 105: "num_9",
            106: "num_multiply", 107: "num_add", 108: "num_enter", 109: "num_subtract", 110: "num_decimal", 111: "num_divide",
            124: "print", 144: "num", 145: "scroll",
            186: ";", 187: "=", 188: ",", 189: "-", 190: ".", 191: "/", 192: "`", 219: "[", 220: "\\", 221: "]", 222: "'", 223: "`",
            224: "cmd", 225: "alt", 57392: "ctrl", 63289: "num"
        }

        window.KeyBoardMaps = {
            _callbacks: {}
            _combes: {}
            register: (combe, callback, ctx = @)->
                callback._listenerSequence = callback._listenerSequence || (new Date().getTime() + Math.random() + "")
                combe = @_combes[combe] = @_combes[combe] || []
                @_callbacks[callback._listenerSequence] = {callback: callback, ctx: ctx}
                combe.push(callback._listenerSequence)
                @

            get: (combe)->
                self = @
                if(@_combes[combe])
                    @_combes[combe].map((sequence)->
                        self._callbacks[sequence])

            remove: (combe, callback, ctx = @)->
                sequence = callback._listenerSequence
                combearr = @_combes[combe] = @_combes[combe] || []
                @_combes[combe] = combearr.slice(0,
                    combearr.indexOf(sequence)).concat(combearr.slice(combearr.indexOf(sequence) + 1))
        }

        $(document).on("keydown", (e)->
            keyStack = keyStack.slice(0,
                keyStack.indexOf(e.keyCode)).concat(keyStack.slice(keyStack.indexOf(e.keyCode) + 1)) while keyStack.indexOf(e.keyCode) >= 0
            keyStack.push(e.keyCode)
            triggerString = ''
            triggerString += q[key] + "+" for key in keyStack
            triggerString = triggerString.substr(0, triggerString.length - 1)
            if (cbs = KeyBoardMaps.get(triggerString))
                for evt in cbs
                    setTimeout(->
                        evt.callback.apply(evt.ctx, e)
                    , 1)
                return false
            else
                return true
        )
        $(document).on("keyup", (e)->
            keyStack = []
            return false
        ))()

    $(document).ajaxError((event, request, settings)->
        $(document).trigger("ajaxerror", [event, request, settings]))

    #    继承方法
    _extend = (child, parent, props = {}, staticProps = {})->
        child.prototype = Object.create(parent.prototype)
        for key, value of Object.create(props)
            child.prototype[key] = value
        for key, value of Object.create(parent)
            child[key] = value
        for key, value of Object.create(staticProps)
            child[key] = value
        child.prototype._super = parent.prototype
        return child

    Class = ->
        @constructor(arguments)
        @

    Class.prototype.constructor = ->
        @initialize.apply(@, arguments)
    Class.prototype.initialize = ->
    Class.extend = (props = {}, staticProps = {})->
        self = @
        _Class = ->
            self.prototype.constructor.apply(@, arguments)
        _Class = _extend(_Class, @, props, staticProps)
        _Class.extend = ->
            self.extend.apply(@, arguments)
        return _Class

    Events = window.Events = ->
        @constructor(arguments)
    Events = _extend(Events, Class, {

    # 监听
        on: (signal, callback, ctx = @, evts = (@_events[signal] = @_events[signal] || {}))->
            if(!callback)
                return
            _listenerSequence = callback._listenerSequence = callback._listenerSequence || (new Date().getTime() + Math.random() )
            evts[_listenerSequence] = { callback: callback, ctx: ctx }

        unon: (signal, callback)->
            if @_events[signal] && @_events[signal][callback._listenerSequence]
                delete @_events[signal][callback._listenerSequence]
            if @_onceevents[signal] && @_onceevents[signal][callback._listenerSequence]
                delete @_onceevents[signal][callback._listenerSequence]

    # 监听一次
        once: (signal, callback, ctx = @, evts = (@_onceevents[signal] = @_onceevents[signal] || {}))->
            if(!callback)
                return
            _listenerSequence = callback._listenerSequence = callback._listenerSequence || (new Date().getTime() + Math.random() )
            evts[_listenerSequence] = { callback: callback, ctx: ctx }

    # 发送
        trigger: (signal, args = [])->
            ((->
                delete evts[evtSeq]
                setTimeout((->
                    if evt && evt.callback then evt.callback.apply(evt.ctx, args)
                ), 1))() for evtSeq, evt of evts) if evts = @_onceevents[signal]

            (setTimeout((->
                if evt && evt.callback then evt.callback.apply(evt.ctx, args)
            ), 1) for evtSeq, evt of evts) if evts = @_events[signal]
    })

    Events.prototype.constructor = ->
        @_events = {}
        @_onceevents = {}
        @initialize.apply(@, arguments)
        @

    _Sys = Events.extend({ initialize: -> })

    window.Sysweb = window.Sysweb || (->
        new _Sys())()

    fs = Sysweb.fs = (->
        resultHandler = (result)->
            if(result.error)
                newfs.trigger("fserror", arguments)

        _Fs = _Sys.extend({

        # 变更目录
            cd: (path)->
                $.get("/fs/cd", {
                    path: path
                }).done(resultHandler)

        # 查看目录下的文件的详细信息
            ls: (path)->
                $.get("/fs/ls", {
                    path: path
                }).done(resultHandler)

        # 查看当前目录
            pwd: ()->

                # 是否存在目录
            isDir: (path)->
                $.get("/fs/isDir", {
                    path: path
                }).done(resultHandler)

        # 是否存在文件
            isFile: (path)->
                $.get("/fs/isFile", {
                    path: path
                }).done(resultHandler)
        # 新建文件
            touch: (path)->
                $.post("/fs/touch", {
                    path: path
                }).done(resultHandler)

        # 新建文件夹
            mkdir: (path)->
                $.post("/fs/mkdir", {
                    path: path
                }).done(resultHandler)

        # 删除
            rm: (path)->
                $.post("/fs/rm", {
                    path: path
                }).done(resultHandler)

        # 复制
            cp: (source, dest)->
                $.post("/fs/cp", {
                    source: source
                    dest: dest
                }).done(resultHandler)
        # 移动
            mv: (source, dest)->
                $.post("/fs/mv", {
                    source: source
                    dest: dest
                }).done(resultHandler)

        # 查看开头几行
            head: (path, start, stop)->
                $.post("/fs/head", {
                    path: path
                    start: start
                    stop: stop
                }).done(resultHandler)

        # 查看末尾几行
            tail: (path, start, stop)->
                $.post("/fs/tail", {
                    path: path
                    start: start
                    stop: stop
                }).done(resultHandler)

        # 查看文件状态
            stat: (path)->
                $.get("/fs/stat", {path: path}).done(resultHandler)

        # 阅读文件
            read: (path)->
                $.post("/fs/read", {
                    path: path
                }).done(resultHandler)

        # 重写文件
            write: (path, text)->
                $.post("/fs/write", {
                    path: path
                    text: text
                }).done(resultHandler)

        # 在文件末尾添加
            append: (path, text)->
                $.post("/fs/append", {
                    path: path
                    text: text
                }).done(resultHandler)

            echo: (path, text)->
                $.post("/fs/echo", {
                    path: path
                    text: text
                }).done(resultHandler)

            head: (path)->
                $.get("/fs/head", {
                    path: path
                }).done(resultHandler)
        })
        newfs = new _Fs()

        newfs)()

    Sysweb.Memory = (->
        _Memory = _Sys.extend({})
        new _Memory())()

    Sysweb.Library = (->
        _Library = _Sys.extend({
            initialize: ->
                @_libs = {}

            addLib: (name, lib)->
                if (!@_libs[name])
                    @_libs[name] = lib
                @
            getLib: (name)->
                @_libs[name]
            removeLib: (name)->
                delete @_libs[name]
                @
        })
        new _Library())()

    window.Sysweb.Environment = (->
        _Environment = _Sys.extend({
            initialize: ->
                @_envs = {}
            set: (name, value)->
                @_envs[name] = value
            get: (name)->
                @_envs[name]
            addBoot: (tag, path, attr, attrs = '')->
                $.post("/boot", {
                    tag: tag
                    path: path
                    attr: attr
                    attrs: attrs
                })
        })
        new _Environment())()

    window.Sysweb.Applications = (->
        _Apps = _Sys.extend({
            AppClass: Events.extend({})
            initialize: ->
                @_apps = {}
            set: (name, value)->
                if @_apps[name]
                    return false
                @_apps[name] = value
            get: (name)->
                @_apps[name]
        })
        new _Apps())()

    window.Sysweb.User = (->
        _User = _Sys.extend({
            initialize: ->
                self = @
                @fetch().done(()->
                    document.getElementsByTagName('head')[0].appendChild(document.createElement('script')).setAttribute('src', "/sys_root/#{Sysweb.User.currentUser.username}/__sys.js");
                )
                $(document).on "ajaxerror", (docevent, event, request, settings)->
                    if(request.status == 403)
                        self.trigger("forbidden", [event, request, settings])

            login: (params = {})->
                """ @parems email password """
                self = @
                $.post("/login", params).done((result)->
                    if(!result.error && result.user)
                        self.currentUser = result.user
                        self.trigger("logined")
                        window.location.reload()
                    else
                        self.trigger("loginfailed")
                )
            register: (params = {})->
                """ @parems email password """
                self = @
                $.post("/register", params).done((result)->
                    if(!result.error && result.user)
                        self.currentUser = result.user
                        self.trigger("logined")
                    else
                        self.trigger("registerfailed")
                )
            fetch: ()->
                self = @
                $.post("/user/current").done((result)->
                    if(!result.error && result.user)
                        self.currentUser = result.user
                        self.trigger("logined")
                )
        })
        new _User())()











