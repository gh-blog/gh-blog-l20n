fs = require 'fs'
{ Parser, Compiler } = require 'l20n'
moment = require 'moment'
_ = {
    omit: require 'lodash.omit'
    cloneDeep: require 'lodash.clonedeep'
    defaults: require 'lodash.defaults'
}

through2 = require 'through2'

module.exports = (options) ->
    { localeCode, blog } = options

    parser = new Parser
    compiler = new Compiler
    localeCode = localeCode.toLowerCase()
    localeFiles = {
        blog: "#{__dirname}/locales/blog.#{localeCode}.l20n"
        post: "#{__dirname}/locales/post.#{localeCode}.l20n"
        indexPage: "#{__dirname}/locales/index_page.#{localeCode}.l20n"
    }

    try
        if localeCode isnt 'en-us'
            require "moment/locale/#{localeCode || blog.language || 'en-us'}"

        moment.locale localeCode

    catch e
        # @TODO: handle errors
        console.log e
        throw new Error 'Language specified for l20n does not currently have
        a translation, please contribute one at https://github.com/gh-blog/\
        gh-blog-l20n'

    blog = _.defaults blog, dateFormat: 'LL'

    compile = (localeFile) ->
        localeFileContent = fs.readFileSync localeFile
        code = localeFileContent.toString()
        ast = parser.parse code
        compiler.compile ast

    data = { blog }

    data.blog.formatDate = (date, format = blog.dateFormat) ->
        (moment date).format(format)

    # Compile global blog strings
    blogEntries = compile localeFiles.blog
    data.blog.strings = { }
    for key, entry of blogEntries
        if not entry.expression
            try
                data.blog.strings[key] = entry.getString data

    processFile = (file, enc, done) ->
        try
            switch
                when file.isPost then localeFile = localeFiles.post
                when file.isIndexPage then localeFile =localeFiles.indexPage
                else
                    return done null, file

            data.file = file
            entries = compile localeFile
            file.strings = { }
            for key, entry of entries
                if not entry.expression
                    try
                        file.strings[key] = entry.getString data
                    # catch e
                    #     throw e
                        # @TODO: handle


            done null, file

        catch e
            console.log '[L20n] Error:', e
            return done e, file

    through2.obj processFile