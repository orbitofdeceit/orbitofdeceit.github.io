---
layout: null
---
<head>
<title>Add New Haiku</title>
<style>
#grid {
    display: grid;
    grid-template-columns: 5% 30%;
}
* {
 font-size: 10pt;
 font-family: Verdana, Arial;
}
</style>
</head>
<body>
<form action="https://api.orbitofdeceit.com/haiku" method="POST" name="add-haiku" id='json-form'>
    <div id="grid">
    <label>API Key</label><input type="password" name="secret">
    <div></div><br/>
    <label>Title</label><input type="text" name="title">
    <label>File</label><input type="filename" name="filename">
    <div></div><br/>
    <label>Haiku</label><input type="text" name="line-0">
    <div></div><input type="text" name="line-1">
    <div></div><input type="text" name="line-2">
    </div>
    <input type="submit" value="Add" hidden="true">
</form>
</body>
<script type="module" src="main.js"></script>
