fs = require 'fs'
{ Parser, Compiler } = require 'l20n'
moment = require 'moment'
_ = require 'lodash'

through2 = require 'through2'

module.exports = (localeCode, blog) ->
    require "moment/locale/#{localeCode || blog.language || 'en'}"
    moment.locale localeCode
    parser = new Parser
    compiler = new Compiler
    localeFile = "#{__dirname}/locales/post.ar.l20n"
    localeFileContent = fs.readFileSync(localeFile)
    blog = _.defaults blog, dateFormat: 'LL'

    compile = ->
        code = localeFileContent.toString()
        ast = parser.parse code
        compiler.compile ast

    processFile = (file, enc, done) ->
        if file.isPost
            data = { blog }
            data.post = _.cloneDeep _.omit file, 'contents', '$'

            try
                entries = compile localeFile
                file.strings = { }
                for key, entry of entries
                    if !entry.expression
                        try file.strings[key] = entry.getString data

                file.formatDate = (date) ->
                    moment(date).format(blog.dateFormat)

                done null, file
            catch e
                console.log 'L20n error:', e
                done e
        else
            done null, file

    through2.obj processFile