fs = require 'fs'
{ Parser, Compiler } = require 'l20n'
moment = require 'moment'
_ = require 'lodash'

through2 = require 'through2'

module.exports = (localeCode, blog) ->
    parser = new Parser
    compiler = new Compiler
    localeCode = localeCode.toLowerCase()
    localeFile = "#{__dirname}/locales/post.#{localeCode}.l20n"
    try
        if localeCode isnt 'en-us'
            require "moment/locale/#{localeCode || blog.language || 'en-us'}"

        moment.locale localeCode
        localeFileContent = fs.readFileSync(localeFile)
    catch e
        # @TODO: handle errors
        console.log e
        throw new Error 'Language specified for l20n does not currently have
        a translation, please contribute one at https://github.com/forabi/\
        pipelog-l20n'

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
                    moment(date).format blog.dateFormat

            catch e
                console.log 'L20n error:', e
                return done e, file

        done null, file

    through2.obj processFile