# frozen_string_literal: true

require 'ics'
require 'events/event'
require 'Tempfile'
require 'Date'

RSpec.describe ICS do
  before(:all) do
    $stdout = File.open(File::NULL, 'w')
  end

  describe ICS::FileParser do
    let(:ics_file) do
      <<~ICSFILE
        BEGIN:VCALENDAR
        PRODID:-//Grafik-Partner GmbH//Muellmax 7.0 MIMEDIR//EN
        VERSION:2.0
        METHOD:PUBLISH
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20180216
        DTEND;VALUE=DATE:20180217
        DESCRIPTION:Wissenschaftsstadt Darmstadt\n
        Eigenbetrieb für kommunale Aufgaben und Dienstleistungen (EAD)\n
        vertreten durch die Betriebsleitung\n
        Sensfelder Weg 33\n
        64293 Darmstadt\n
        \n
        Service-Telefonnummer: 06151 / 13 46 000\n
        Fax: 06151 / 1346 393\n
        mailto:ead@darmstadt.de\n
        http://www.ead.darmstadt.de
        LOCATION:64287 Darmstadt-Innenstadt, Soderstraße 36-Ende, 39-Ende
        TRANSP:TRANSPARENT
        SEQUENCE:0
        UID:15183587251@muellmax.de
        DTSTAMP:20180211T141845Z
        SUMMARY:EAD Restabfall wöchentliche Leerung
        CLASS:PUBLIC
        CREATED:20180112T145036Z
        LAST-MODIFIED:20180112T145036Z
        URL:http://www.muellmax.de
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20180223
        DTEND;VALUE=DATE:20180224
        DESCRIPTION:Wissenschaftsstadt Darmstadt\n
        Eigenbetrieb für kommunale Aufgaben und Dienstleistungen (EAD)\n
        vertreten durch die Betriebsleitung\n
        Sensfelder Weg 33\n
        64293 Darmstadt\n
        \n
        Service-Telefonnummer: 06151 / 13 46 000\n
        Fax: 06151 / 1346 393\n
        mailto:ead@darmstadt.de\n
        http://www.ead.darmstadt.de
        LOCATION:64287 Darmstadt-Innenstadt, Soderstraße 36-Ende, 39-Ende
        TRANSP:TRANSPARENT
        SEQUENCE:0
        UID:15183587252@muellmax.de
        DTSTAMP:20180211T141845Z
        SUMMARY:EAD Restabfall wöchentliche Leerung
        CLASS:PUBLIC
        CREATED:20180112T145036Z
        LAST-MODIFIED:20180112T145036Z
        URL:http://www.muellmax.de
        END:VEVENT
        END:VCALENDAR
      ICSFILE
    end

    describe 'parse_ics_date' do
      it 'parses ICS Dates correctly' do
        actual = ICS::FileParser.parse_ics_date '20180216'
        expect(actual).to be_instance_of Date
        expect(actual.to_s).to eq '2018-02-16'
      end
    end

    describe 'stripLine' do
      it 'removes leading whitespace' do
        actual = ICS::FileParser.clean_line '    foobar'
        expect(actual).to eq 'foobar'
      end

      it 'removes trailing whitespace' do
        actual = ICS::FileParser.clean_line 'foobar     '
        expect(actual).to eq 'foobar'
      end

      it 'removes leading and trailing whitespace' do
        actual = ICS::FileParser.clean_line '   foobar     '
        expect(actual).to eq 'foobar'
      end
    end

    describe 'split_line' do
      it 'properlies split a two segment line' do
        actual_k, actual_v = ICS::FileParser.split_line 'foo:bar'
        expect(actual_k).to eq 'foo'
        expect(actual_v).to eq 'bar'
      end

      it 'properlies split a one segmnent line' do
        actual_k, actual_v = ICS::FileParser.split_line 'foobar'
        expect(actual_k).to be_nil
        expect(actual_v).to eq 'foobar'
      end

      it 'gracefullies handle an empty line' do
        actual_k, actual_v = ICS::FileParser.split_line ''
        expect(actual_k).to be_nil
        expect(actual_v).to be_nil
      end
    end

    describe 'parse_ics' do
      let(:file_path) { Tempfile.new }
      let(:dir_path) { File.dirname(file_path) }

      before do
        Dir.mkdir(dir_path) unless Dir.exist?(dir_path)
        File.open(file_path, 'w') { |handle| handle.write ics_file }
      end

      after do
        File.unlink file_path
      end

      it 'returns a list of events' do
        actual = ICS::FileParser.parse_ics file_path
        expect(actual).to be_instance_of Array
        expect(actual.length).to eq 2
        expect(actual).to all(be_instance_of(Events::Event))
      end

      it 'correctlies parse events' do
        actual = ICS::FileParser.parse_ics file_path
        expect(actual[0].date).to be_instance_of Date
        expect(actual[0].date.day).to eq(16)
        expect(actual[0].date.month).to eq(2)
        expect(actual[0].date.year).to eq(2018)
        expect(actual[0].summary).to eq('EAD Restabfall wöchentliche Leerung')
        expect(0..2**30 - 1).to cover actual[0].id
      end
    end
  end
end
