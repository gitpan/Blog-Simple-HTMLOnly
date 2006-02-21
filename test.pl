
use Test;
use strict;
use HTML::TokeParser;

BEGIN { plan tests => 6 };
use Blog::Simple::HTMLOnly;
ok(1); # If we made it this far, we're ok.

#########################
my $tmp;
foreach ($ENV{TEMP}, $ENV{TMP}, '/tmp', '/temp', '/usr/tmp', 'C:/temp'){
	next if not defined $_;
	$tmp = $_;
	last if -d $tmp;
}

if ( not defined $tmp){
	print "Skip all - no temporary directory found.\n";
	exit;
}


my $sbO = Blog::Simple::HTMLOnly->new($tmp);
ok( ref $sbO, "Blog::Simple::HTMLOnly");
$sbO->create_index(); #generally only needs to be called once

my $content = "<p>blah blah blah in XHTM</p><p><b>Better</b> when done in
HTML!</p>";
my $title = 'some title';
my $author = 'a.n. author';
my $email = 'anaouthor@somedomain.net';
my $smmry = 'blah blah';
$sbO->add($title,$author,$email,$smmry,$content);

my $format = {
	simple_blog	=> '<div class="box">',
	title 		=> '<div class="title"><b>',
	author 		=> '<div class="author">',
	email 		=> '<div class="email">',
	ts			=> '<div class="ts">',
	summary		=> '<div class="summary">',
	content		=> '<div class="content">',
};
my $html = $sbO->render_current($format,3);
ok(ref $html,'SCALAR');

my $p = HTML::TokeParser->new($html);
ok( ref $p->get_tag("b"), 'ARRAY');
ok( $p->get_trimmed_text, 'some title');

ok( ref $sbO->render_all($format), 'SCALAR');

exit;
__END__

