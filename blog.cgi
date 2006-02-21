#!/usr/bin/perl

#
# blog.cgi        			- display the current blog
# blog.cgi?x      			- where 'x' is anything: add a blog
# blog.cgi?all=1&author=y   - display all the blogs of author 'y'
# blog.cgi?date=x&author=y	- where 'x' and 'y' are a timestamp
#                 			  and an author name: shows that blog
#
# ...&template=false   - do not use the template
#
# Copyright (C) 2003, Lee Goddard (lgoddard -at- cpan -dot- org)
# All Rights Reserved. Available under the same terms as Perl.
#

my $VERSION = 0.1;

use CGI::Carp qw(fatalsToBrowser);
use strict;
use Blog::Simple::HTMLOnly;
use HTML::Calendar::Simple;
use CGI 2.47 qw/:standard/;
use Cwd;

my $PASSWORD = 'password';

my $TEMPLATE_PATH = "/home/leeg1644/public_html/blank.html";

my $BLOG_DIR = {
	Polar 	=> '/home/leeg1644/private_data/Polar_Blog',
	Lee		=> "/home/leeg1644/private_data/Lee_Blog",
};

my ($TEMPLATE_TOP, $TEMPLATE_BOTTOM, $FORMAT, $TITLE);

my $cgi 	= CGI->new;
my $blogger;

# Set blog-base by author
if ($cgi->param('author') and $cgi->param('author') eq 'Polar'){
	$blogger = Blog::Simple::HTMLOnly->new($BLOG_DIR->{$cgi->param('author')});
	$TITLE = "Weblog";
	$FORMAT = {
		simple_blog_wrap => '<div>',
		simple_blog => '<div style="font-family:Arial">',
		title       => '<h2 style="color:silver;font-family:\'Arial Black\';margin-top:5px;margin-bottom:5px">',
		author      => '<span style="display:none">',
		email       => '<span style="display:none">',
		ts          => '<p style="color:gray;font-size:10px;margin:0;margin-left:1em"><i><small>',
		summary     => '<h4 style="color:gray;margin-bottom:5px;margin-top:5px;">',
		content     => '<div style="font-size:10px">',
	};
} else {
	$blogger = Blog::Simple::HTMLOnly->new($BLOG_DIR->{$cgi->param('author') || 'Lee'});
	$TITLE = 'Moaning&nbsp;and Groaing at the Edge of ...';
	$FORMAT = {
		simple_blog_wrap => '<div>',
		simple_blog => '<div style="width:100%;padding:1em;border:1px double olive;margin-bottom:1em;">',
		title       => '<h1 style="margin-bottom:5px;font-style:italic">',
		author      => '<span style="display:none">',
		email       => '<span style="display:none">',
		ts          => '<p style="font-size:8px;margin:0;margin-left:1em"><i><small>',
		summary     => '<h4 style="margin-bottom:5px;margin-top:5px;">',
		content     => '<div style="margin-left:3em">',
	};
}

if (!-e $blogger->{blog_idx}){
	$blogger->create_index();
	$blogger->add(
		"Blogging...",
		$cgi->param('author'),
		'me@example.com',
		'Started to blog',
		"<p>This is the first blog using Perl module <code>"
		.__PACKAGE__."</code>, which I sub-classed from <code>Blog::Simple</code> and put on CPAN.</p>"
	);
}

if ($cgi->param('template') and $cgi->param('template') eq 'false'){
	print $cgi->header;
	$ENV{QUERY_STRING} = "";
} else {
	&print_header
}

if ($ENV{QUERY_STRING}){
	if ($cgi->param('all') or $ENV{QUERY_STRING} eq 'all'){
		$blogger->render_all($FORMAT);
	}
	elsif ($ENV{QUERY_STRING} and $cgi->param('date') and $cgi->param('author')){
		my $date = $cgi->param('date');
		my $cleandate = $date;
		$cleandate =~ s/[_:]/ /g;
		if (localtime($cleandate) eq 'Thu Jan  1 01:02:03 1970'){
			print "The supplied value, <code>".($date)."</code> is not a legal date!";
		} elsif (!-e $blogger->{blog_base}.$date."_".$cgi->param('author')){
			print "The blog of $date, by ",$cgi->param('author'),", could not be found.";
			print "\n<!-- $!: ",$blogger->{blog_base}.$cleandate."_".$cgi->param('author')," -->\n";
		} else {
			&show_blog($date,$cgi->param("author"));
		}
	}
	elsif ($cgi->param('title') and $cgi->param('title') ne ''
		and $cgi->param('author') and $cgi->param('author') ne ''
		and $cgi->param('email') and $cgi->param('email') ne ''
		and $cgi->param('summary') and $cgi->param('summary') ne ''
		and $cgi->param('content') and $cgi->param('content') ne ''
	){
		if (not $cgi->param('password') or $cgi->param('password') ne $PASSWORD){
			&form('You either supplied the wrong password or none at all.');
		} else {
			my $content = &format_text($cgi->param('content')) ;
			$blogger->add(
				$cgi->param('title'),
				$cgi->param('author'),
				$cgi->param('email'),
				$cgi->param('summary'),
				$content
			);
			print h1("Blogged!");
			$blogger->render_current($FORMAT,1);
			print p("<a href='$ENV{SCRIPT_NAME}?all'>SHOW ALL BLOGS</a>");
		}
	} else {
		my $err = join", ", (grep { $cgi->param($_) eq '' } $cgi->param);
		if ($err){
			$err = "Your forgot to do the <i>$err</i>.";
		}
		&form($err);
	}
} else {
	$blogger->render_current($FORMAT,1);
}

&print_footer unless $cgi->param('template') and $cgi->param('template') eq 'false';
exit;

sub print_header {
	local (*IN,$_);
	open IN,$TEMPLATE_PATH or die "Could not open $TEMPLATE_PATH from dir ".cwd;
	read IN,$_,-s IN;
	close IN;
	($TEMPLATE_TOP,$TEMPLATE_BOTTOM) = /^(.*)<!--\sinsert.*?-->(.*)$/sig;
	$TEMPLATE_TOP =~ s/<\s*title\s*>.*?<\/\s*title\s*>/<title>$TITLE<\/title>/si;
	print $cgi->header, $TEMPLATE_TOP;
}

sub print_footer { print $TEMPLATE_BOTTOM }

sub form { my $err=shift;
	print
		h1("Add a Blog"),
		($err? h3($err):""),
		start_form,
		"<table align='center' cellpadding='1' cellspacing='1' border='0'>\n",
		"<tr>",
		"<td>Title:</small></td><td>",
		textfield(
			-name=>'title',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>Summary: </td><td>",
		textfield(
			-name=>'summary',
			-default=>'',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>Content:</small></td><td>",
		"<textarea name='content' rows='15' cols='50' wrap='hard'>",
		$cgi->param("content")?$cgi->param("content"):"",
		"</textarea>",
		"</td></tr><tr><td>",
		"Author: </td><td>",$cgi->popup_menu(
			-name=>'author',
			-values=>[qw/Lee Polar/],
			-default=>'Lee'
		),
		"</td></tr><tr><td>",
		"E-mail: </td><td>", textfield(
			-name=>'email',
			-default=>'me@example.com',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>",
		"Password: </td><td>",
		password_field(
			-name=>'password',
			-default=>'',
			-override=>1,
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td colspan='2'><hr size='1'/>",
		"</td></tr><tr><td>&nbsp;</td><td>",
		submit,
		"</td></tr></table>",
		end_form;
}


sub show_blog { my ($date,$author) = (shift,shift);
	local *IN;
	my $xmlString;
	unless (open IN, $blogger->{blog_base}.$date."_".$author."/blog.xml"){
		print "Could not find blog, <pre>",
			$blogger->{blog_base}.$date."_".$author,
			"</pre>";
		return undef;
	}
	read IN,$xmlString,-s IN;
	close IN;
	my $html = $blogger->transform ($FORMAT,\$xmlString);
	print $$html;
}


sub format_text {
	@_ = map {"<p>$_</p>"} split (/[\n\r\f]+/,shift) ;
	return join ("",@_);
}







