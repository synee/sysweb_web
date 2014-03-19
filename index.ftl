<!DOCTYPE html>
<html>
<head>
    <title>Sysweb</title>
    <link rel="stylesheet" href="/assets/less/finder.css">
</head>
<body>

<script src="/script/Library/jquery.js"></script>
<script src="/script/Library/corelib.min.js"></script>
<script src="/script/Applications/terminal.js"></script>
<#if session['currentUser'].exists()>
    <script src="/sys_root/${session['currentUser'].getUsername()}/__sys.js"></script>
</#if>
</body>
</html>