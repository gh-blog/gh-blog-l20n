fs = require 'fs'
{ Parser, Compiler } = require 'l20n'
moment = require 'moment'
_ = require 'lodash'

through2 = require 'through2'

module.exports = (localeFile, localeCode='en', blog) ->
    require "moment/locale/#{localeCode}"
    moment.locale localeCode
    parser = new Parser
    compiler = new Compiler
    localeFileContent = fs.readFileSync(localeFile)
    blog = _.defaults blog, dateFormat: 'LL'

    compile = ->
        code = localeFileContent.toString();
        ast = parser.parse code
        compiler.compile ast

    processFile = (file, enc, done) ->
        data = { blog }

        if file.dateAdded
            file.dateAdded.toLocaleString = ->
                moment(file.dateAdded).format(blog.dateFormat)

        if file.dateModified
            file.dateModified.toLocaleString = ->
                moment(file.dateModified).format(blog.dateFormat)

        if file.isPost
            data.post = _.cloneDeep _.omit file, 'contents', '$'

        try
            entries = compile localeFile
            file.strings = { }
            for key, entry of entries
                if !entry.expression
                    try file.strings[key] = entry.getString data

            done null, file
        catch e
            console.log 'L20n error:', e
            done e, file

    through2.obj processFile