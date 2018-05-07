class IncomingInlineQuery

    @messageid = nil
    @queryid = nil
    @data = nil
    def(messageid, queryid, data)
        @messageid = messageid
        @queryid = queryid
        @data = data
    end
end
