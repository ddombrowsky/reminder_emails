#!/usr/bin/perl
#

use warnings;
use strict;

use XML::LibXML::Reader;
use LWP::UserAgent;
use Date::Manip;
use HTML::Entities;

# only display items between these two dates (inclusive)
my $MINDATE = ParseDate("now") || die;
my $MAXDATE = DateCalc($MINDATE, "+7 days") || die;

print("Displaying scheduled tasks for week\n".
      "\tstarting ".UnixDate($MINDATE,"%Y-%m-%d")."\n".
      "\t  ending ".UnixDate($MAXDATE,"%Y-%m-%d")."\n\n");

sub readNode($$)
{
    my $reader = shift;
    my $name = shift;
    my $ret = undef;

    # next element should be the text
    $reader->read();
    if(($reader->nodeType == XML_READER_TYPE_TEXT) &&
       $reader->value)
    {
        $ret = decode_entities($reader->value);
    }else{
        printf("parse error: #text doesn't follow $name\n");
    }
    return $ret;
}

sub processEntry($)
{
    my $reader = shift;
    my $state = 0;
    my $title;
    my $summary;

    while($reader->read()){

        if (0) {
            # debugging...
            printf("%s %d %d %s %d\n",
                " " x $reader->depth,
                $reader->depth,
                $reader->nodeType,
                $reader->name,
                $reader->isEmptyElement
            );
            if($reader->value){
                print(decode_entities($reader->value)."\n");
            }
        }

        # skip end elements, we're not that smart
        if($reader->nodeType == XML_READER_TYPE_END_ELEMENT){
            next;
        }

        my $ename = $reader->name;

        if($state == 0){
            if($ename eq 'title') {
                $title = readNode($reader, 'title');
                if($title){
                    $state = 1;
                    $summary = undef;
                }
            }
        }elsif($state == 1){
            if($ename eq 'summary') {
                $summary = readNode($reader, 'summary');
                if($summary){
                    if($title){
                        $state = 0;

                        # Date is stored in summary (of course it is!).
                        # If it falls within the range, print it.
                        my $date;
                        if($summary =~ /When: (.*)\</){
                            $date = $1;
                            my $d = ParseDate($date);
                            if((Date_Cmp($MINDATE,$d) <= 0) &&
                               (Date_Cmp($d,$MAXDATE) <= 0))
                            {
                                print($title." : ".$date."\n");
                            }
                        }
                    }else{
                        print("parse error: no title for summary $summary\n");
                    }
                }
            }
        }


    }
}

sub processFeed($)
{
    my $reader = shift;

    # skip everything that isn't a calendar entry
    if(($reader->nodeType == XML_READER_TYPE_ELEMENT) &&
       ($reader->name eq "entry"))
    {
        processEntry($reader);
    }
}

#
# main
#



my $ua = LWP::UserAgent->new;
$ua->timeout(60);

my $response = $ua->get("https://www.google.com/calendar/feeds/t4lkdbnmv3j0ogp9hlhb3ujj14%40group.calendar.google.com/public/basic");

if($response->is_success){
    my $xml = $response->decoded_content();
    my $reader = XML::LibXML::Reader->new(string => $xml);

    while($reader->read()){
        processFeed($reader)
    }
}

