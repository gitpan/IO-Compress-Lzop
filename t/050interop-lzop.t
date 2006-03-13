BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ;

my $LZOP ;

BEGIN {

    # Check external lzop is available
    my $name = 'lzop';
    for my $dir (reverse split ":", $ENV{PATH})
    {
        $LZOP = "$dir/$name"
            if -x "$dir/$name" ;
    }

    plan(skip_all => "Cannot find lzop")
        if ! $LZOP ;

    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 17 + $extra ;

    use_ok('IO::Compress::Lzop', qw(:all)) ;
    use_ok('IO::Uncompress::UnLzop', qw(:all)) ;

}

use CompTestUtils;

sub readWithLzop
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    my $comp = "$LZOP -dc" ;

    #diag "$comp $file >$outfile" ;

    system("$comp $file >$outfile") == 0
        or die "'$comp' failed: $?";

    $_[0] = readFile($outfile);

    return 1 ;
}


sub getLzopInfo
{
    my $file = shift ;
}

sub writeWithLzop
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $gzip = "$LZOP -c $options $infile >$file" ;

    system($gzip) == 0 
        or die "'$gzip' failed: $?";

    return 1 ;
}


{
    title "Test interop with $LZOP" ;

    my $file;
    my $file1;
    my $lex = new LexFile $file, $file1;
    my $content = "hello world\n" ;
    my $got;

    is writeWithLzop($file, $content), 1, "  writeWithLzop ok";

    ok unlzop($file => \$got), "  unlzop ok" ;
    is $got, $content, "  got expected content";


    ok lzop(\$content => $file1), "  lzop ok";
    $got = '';
    is readWithLzop($file1, $got), 1, "readWithLzop returns 0";
    is $got, $content, "got content";
}


{
    title "No Checksums";

    my $lex = new LexFile my $file;
    my $content = "hello world\n" ;
    my $got;

    is writeWithLzop($file, $content, '-F'), 1, "  writeWithLzop ok";

    ok unlzop($file => \$got, Strict => 1), "  unlzop ok" ;
    is $got, $content, "  got content";
}

{
    title "CRC32";

    my $lex = new LexFile my $file;
    my $content = "hello world\n" ;
    my $got;

    is writeWithLzop($file, $content, '--crc32'), 1, "  writeWithLzop ok";

    ok unlzop($file => \$got, Strict => 1), "  unlzop ok" ;
    is $got, $content, "  got content";
}

