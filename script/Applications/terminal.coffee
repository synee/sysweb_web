$(()->
    Applications = window.Sysweb.Applications

    Terminal = Events.extend
        currentDir: "/"

        template: """
                    <div id='terminal' style=' font-family: monospace; font-size: 12px;'>
                        <div id='terminal_output'></div>
                        <div id='terminal_input' style='margin-bottom: 250px'>
                            <span id='terminal_path' style='color: #f8c; display: inline-block; float: left; line-height: 19px; padding: 0 6px 0 0;'>#{@currentDir} ~#</span>
                            <input style='margin: 0;color: #0fc; background: #333; border: 0; outline: none; width: 80%; float: left; font-family: monospace;padding-top: 2px; '/>
                        </div>
                    </div>
                  """
        style:
            position: "fixed"
            top: 0
            left: 0
            width: "100%"
            height: "100%"
            padding: "10px"
            background: "#333"
            color: "#0fc"
            overflow: "auto"

        $: (selector)->
            @$el.find.apply(@$el, arguments)

    # 已经输入
        hasInputs: []
    # 当前输入
        currentInput: 0

    # 前一个输入
        prevInput: ->
            @currentInput = @currentInput - 1
            if @currentInput < 0
                @currentInput = 0
            if(@hasInputs[@currentInput])
                @$input.val(@hasInputs[@currentInput])
                @$input.focus()
                @$input[0].selectionEnd = @$input.val().length
                return false
            else
                @currentInput = @hasInputs.length
                @$input.val("")

    # 后一个输入
        nextInput: ->
            @currentInput = @currentInput + 1
            if(@hasInputs[@currentInput] == undefined)
                @$input.val(@hasInputs[@currentInput])
                @$input.focus()
                @$input[0].selectionEnd = @$input.val().length
                return false
            else
                @currentInput = @hasInputs.length
                @$input.val("")

    # 输出 Element
        outputEl: (message) ->
            $("""<div class='output_line' style='font-family: monospace; font-size: 12px; padding: 2px 0;'>#{message}</div>""")

    # 输出
        output: (message = '') ->
            $output = @outputEl(message)
            @$outputBox.append($output)
            $output

    # 输出错误
        outputError: (message = '')->
            $o = @output()
            $o.append($("<span style='padding: 5px 20px; color: #f66;'>#{message}</span>"))
            @goon()

    # 提交命令
        commit: (line = @line = @$input.val())->
            $o = @output()
            $o.append($("<span style='padding: 5px 5px 5px 0px; color: #f8c;'>#{@$('#terminal_path').text()}</span>"))
            $o.append($("<pre style='padding: 3px 5px 3px 2px; display: inline;'>#{$("<div/>").text(line).html()}</pre>"))
            if @$input.val()
                @hasInputs[@hasInputs.length] = @$input.val()
            @$input.val("").hide()
            @$("#terminal_path").text("")
            if (!line.trim())
                @goon()
                return
            @execute(line)

    # getParam
        getParam: (name) ->
            args = @line.split(/\s+/)
            if(args.indexOf(name) >= 0)
                return args[args.indexOf(name) + 1]
            else
                return undefined

    # 执行命令
        execute: (line)->
            self = @
            argArr = line.split(/\s+/)
            fnName = argArr[0]
            fn = (Terminal.commandFunctions)[fnName]
            if (fn)
                fn.apply(@, [line, argArr.slice(1)].concat(argArr.slice(1)))
            else
                $o = @output()
                $o.append($("""<span style='padding: 5px 20px; color: #f66;'>No Such command: \" #{fnName} \"</span>"""))
                self.goon()

    # 命令结束， 继续
        goon: ()->
            @$("#terminal_path").text("Sysweb:#{@currentDir}  #{if Sysweb.User.currentUser && Sysweb.User.currentUser.username then Sysweb.User.currentUser.username else 'Anonymous'}$")
            @$input.val("").show().focus()
            @$el.animate({ scrollTop: @$("#terminal_output").height()}, 50)
            @currentInput = @hasInputs.length

        getOpreateDir: (path)->
            cDir = @currentDir.substr(0, @currentDir.lastIndexOf("/"))
            path = path.replace("//", "/") while path.indexOf("//") >= 0
            if (path.indexOf("..") == 0)
                cDir = cDir.substr(0, cDir.lastIndexOf("/"))
                path = path.replace("..", "")
                if(path.indexOf("/") == 0)
                    path = path.substr(1)
            if (path.indexOf(".") == 0)
                path = path.substr(1)
                if(path.indexOf("/") == 0)
                    path = path.substr(1)
            if (path.indexOf("/") == 0)
                cDir = ""
            path = cDir + "/" + path
            path = path.substr(0, path.length - 1) while path.lastIndexOf("/") == path.length - 1 && path.length > 0
            path = path.replace("//", "/") while path.indexOf("//") >= 0
            return path

        initialize: (@args = {}
                     @template = @args.template || @template
                     @style = @args.style || @style)->
            $("#terminal").remove() if $("#terminal").length > 0
            @$el = $(@template).css(@style)
            $("body").append(@$el)
            @$outputBox = @$("#terminal_output")
            @$input = @$("#terminal_input input")
            @initHotkey()
            @initEvents()
            @initCommands()
            @goon()

        initHotkey: ->
            self = @
            KeyBoardMaps.register("ctrl+c", ()->
                self.commit('')
                self.goon()
            )


        initEvents: ->
            self = @
            @$el.on("click", ->
                self.$input.focus())
            @$input.on("keydown", (e)->
                self.keyBoardListener(e))
            Sysweb.User.on("logined", @goon, @)
            Sysweb.User.on("forbidden", ->
                @outputError("Command forbidden, you have to log in.")
                @goon()
            , @)
            Sysweb.fs.on("fserror", (result)->
                self.outputError(result.message)
                self.goon()
            )

        initCommands: ->

        keyBoardListener: (e)->
            if(e.keyCode == 13)
                return @commit()
            if(e.keyCode == 38)
                return @prevInput()
            if(e.keyCode == 40)
                return @nextInput()


    Applications.set("terminal", Terminal)

    Terminal.getInstance = (args)->
        if (!Terminal.instance)
            Terminal.instance = new Terminal(args)
        Terminal.instance.$("#terminal_input input").focus()
        return Terminal.instance


    # 添加命令
    Terminal.addCommandFunction = (name, fn = (args)->)->
        Terminal.commandFunctions[name] = fn

    # Terminal 命令
    Terminal.commandFunctions =
        pwd: ()->
            @output(@currentDir)
            @goon()

        cd: (line, args, path = path || '.')->
            self = @
            path = @getOpreateDir(path) + "/"
            Sysweb.fs.isDir(path).done((result)->
                if(result.isDir)
                    self.currentDir = path
                self.goon()
            )

        ls: (line, args, path = path || ".")->
            self = @
            Sysweb.fs.ls(self.getOpreateDir(path)).done((result)->
                $o = self.output()
                $o.append($("<span style='padding: 5px 20px; color: #{if item.file then "#f99" else "#99f"}'>#{item.name}</span>")) for item in result
                self.goon()
            )

        touch: (line, args, path = path || ".")->
            self = @
            if(args.length < 1)
                @outputError("Missing parameters")
                return @goon()
            path = self.getOpreateDir(path)
            Sysweb.fs.touch(path).done((result)->
                if(result.exists)
                    self.goon()
            )

        read: (line, args, path)->
            self = @
            if(args.length < 1)
                @outputError("Missing parameters")
                return @goon()
            path = self.getOpreateDir(path)
            Sysweb.fs.read(path).done((result)->
                if(result.exists)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                    self.goon()
            )

        write: (line, args, path)->
            self = @
            if(args.length < 2)
                @outputError("Missing parameters")
                return @goon()
            text = line.substr(line.indexOf(path) + path.length)
            path = self.getOpreateDir(path)
            Sysweb.fs.write(path, text).done((result)->
                if(result.exists)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                    self.goon()
            )

        append: (line, args, path)->
            self = @
            if(args.length < 3)
                @output(line.replace("echo", "").trim())
                return @goon()
            text = line.substr(line.indexOf(path) + path.length)
            path = self.getOpreateDir(path)
            Sysweb.fs.append(path, text).done((result)->
                if(result.exists)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                    self.goon()
            )

        echo: (line, args)->
            self = @
            if(args.length < 3 || args[args.length - 2] != ">>")
                @output(line.replace("echo", "").trim())
                return @goon()

            path = @getOpreateDir(args[args.length - 1])
            text = line.substr(5, line.lastIndexOf(">>") - 5).trim()
            if(text.indexOf("\"") == 0)
                text = text.substr(1)
            if(text.lastIndexOf("\"") == text.length - 1)
                text = text.substr(0, text.length - 1)

            Sysweb.fs.echo(path, text).done((result)->
                if(result.exists)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                    self.goon()
            )

        mkdir: (line, args, path = args[0] || "")->
            self = @
            path = self.getOpreateDir(path)
            Sysweb.fs.mkdir(path).done((result)->
                if(!result.error)
                    self.goon()
            )

        rm: (line, args, path)->
            self = @
            path = self.getOpreateDir(line.substr(line.indexOf(" ")).trim())
            Sysweb.fs.rm(path).done((result)->
                if(!result.exists)
                    self.goon()
            )
        cp: (line, args, source = args[0], dest = args[1])->
            self = @
            if (args.length < 2)
                $o = self.output()
                $o.append($("<span style='padding: 5px 20px; color: #f66;'>Args error</span>"))
                self.goon()
                return
            source = self.getOpreateDir(source)
            dest = self.getOpreateDir(dest)
            Sysweb.fs.cp(source, dest).done((result)->
                if(!result.error)
                    self.goon()
            )

        mv: (line, args, source = args[0], dest = args[1])->
            self = @
            if (!source || !dest)
                self.outputError("arguments provided is not enough")
                self.goon()
                return
            source = self.getOpreateDir(source)
            dest = self.getOpreateDir(dest)
            Sysweb.fs.mv(source, dest).done((result)->
                if(!result.error)
                    self.goon()
            )

        head: (line, args, path, start, stop)->
            self = @
            Sysweb.fs.head(self.getOpreateDir(path), start, stop).done((result)->
                if(result.text)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                    self.goon()
            )
        tail: (line, args, path = args[0], start, stop)->
            self = @
            Sysweb.fs.tail(self.getOpreateDir(path), start, stop).done((result)->
                if(result.text)
                    $o = self.output()
                    $o.append($("<pre style='padding: 5px 20px; color: #fff;'>#{$("<div/>").text(result.text).html()}</pre>"))
                self.goon()
            )

    terminal = Terminal.getInstance()

    # Login
    Terminal.addCommandFunction("login", ()->
        self = @
        email = @getParam("-e")
        password = @getParam("-p")
        if(email && password)
            Sysweb.User.login({
                email: email
                password: password
            }).done((result)->
                if(result.user)
                    Sysweb.User.currentUser = result.user
                    Terminal.getInstance().currentDir = "/"
                    $o = terminal.output()
                    $o.append($("<span style='padding: 5px 20px; color: #6f6;'>has login as [#{result.user.username}]</span>"))
                else
                    self.outputError("Login Failed")
                terminal.goon()
            )
        else
            terminal.outputError("Email and password are needed.")
            @goon()
    )

    # Register
    Terminal.addCommandFunction "register", ()->
        self = @
        email = @getParam("-e")
        password = @getParam("-p")
        Sysweb.User.once "registerfailed", ->
            self.goon()
        if(email && password)
            Sysweb.User.register({
                email: email
                password: password
            }).done((result)->
                if (result.error)
                    terminal.outputError(result.message)
                else
                    terminal.output("We have send you an email which to active your account.")
            )
        else
            terminal.outputError('Email and password are needed.')
        @goon()

    Terminal.addCommandFunction "help", (line, args)->
        window.open("/help.html", "_blank")
        @goon()
)