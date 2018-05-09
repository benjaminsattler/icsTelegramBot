class IncomingInlineQuery

    @messageid = nil
    @queryid = nil
    @data = nil
    def initialize(messageid, queryid, data)
        @messageid = messageid
        @queryid = queryid
        @data = data
    end
end
