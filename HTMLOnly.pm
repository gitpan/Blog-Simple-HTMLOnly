package Blog::Simple::HTMLOnly;

use 5.6.1;
use strict;
use warnings;

use base 'Blog::Simple';
our $VERSION = '0.01';

use HTML::TokeParser;

=head1 NAME

Blog::Simple::HTMLOnly - Simple weblog (blogger) with just Core modules.

=head1 SYNOPSIS

	my $sbO = Blog::Simple::HTMLOnly->new();
	$sbO->create_index(); #generally only needs to be called once

	my $content="<p>blah blah blah in XHTM</p><p><b>Better</b> when done in
	HTML!</p>";
	my $title  = 'some title';
	my $author = 'a.n. author';
	my $email  = 'anaouthor@somedomain.net';
	my $smmry  = 'blah blah';
	$sbO->add($title,$author,$email,$smmry,$content);

	my $format = {
		simple_blog_wrap => '<table width='100%'><tr><td>',
		simple_blog => '<div class="box">',
		title       => '<div class="title"><b>',
		author      => '<div class="author">',
		email       => '<div class="email">',
		ts          => '<div class="ts">',
		summary     => '<div class="summary">',
		content     => '<div class="content">',
	};
	$sbO->render_current($format,3);
	$sbO->render_all($format);
	$sbO->remove('08');
	exit;

=head1 DEPENDENCIES

Blog::Simple

=head1 EXPORT

None by default.

=head1 DESCRIPTION

This is a sub-class of C<Blog::Simple>, indentical in all
but the need for C<XML::XSLT>, which an amazingly cheeky ISP
- the English company, TheHostForYou.com - is trying to charge
me to install!

So, instead of C<XML::XSLT>, this module uses C<HTML::TokeParser>,
of the core distribution. Naturally formatting is rather restricted,
but it can produce some useful results if you know your way around
CSS (L<http://www.zvon.org|http://www.zvon.org>), and is better than
a poke in the eye with a sharp stick.

=head1 USAGE

The rendering mthods C<render_current> and C<render_all> no longer
take a paramter of an XSLT file, but instead a reference to a hash,
the keys of which are the names of the nodes in a C<Blog::Simple>
XML file, values being HTML to wrap around the named node.

Only the opening tags need be supplied: the correct end-tags will
supplied in lower-case.

For an example, please see the L</SYNOPSIS>.

=head1 OTHER MODIFICATIONS

The only other things I've changed are:

=over 4

=item *

The render routines C<flock> if not running on Win32.

=item *

The render routines return a reference to a scalar,
which is the formatted HTML.

=back

=head1 DOCUMENTATION

The remaining interface is identical to the parent module:
see L<Blog::Simple>.

=cut

#this method takes a predetermined number of blogs from the top of the 'bb.idx' file
#and generates an output file (HTML). The $format argument is explained in the POD
#
sub render_current { my ($self, $format, $dispNum, $outFile) = (@_);
	#make sure we're getting a reasonable number of blogs to print
	if ($dispNum < 1) { $dispNum = 1; }

	#read in the blog entries from the 'bb.idx' file
	open(BB, "$self->{blog_idx}") or die $self->{blog_idx};
    flock *BB,2 if $^O ne 'MSWin32';
    seek BB,0,0;       # rewind to the start
    truncate BB, 0;	# the file might shrink!
	my @getFiles;
	my $cnt=0;
	while (<BB>) {
		next if (($cnt == $dispNum) || ($_ =~ /^\#/));
		my @tmp = split(/\t/, $_);
		push(@getFiles, $tmp[0]);
		$cnt++;
	}
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';

	#open the 'blog.xml' files individually and concatenate into xmlString
	my $xmlString = "<simple_blog_wrap>\n";
	for (@getFiles) {
		my $fil = $_;
		my $preStr;
		open (GF, "$fil") or die "$fil";
		flock *GF,2 if $^O ne 'MSWin32';
		seek GF,0,0;       # rewind to the start
		truncate GF, 0;	# the file might shrink!
		while (<GF>) { $preStr .= $_; }
		close GF;
		flock (*GF, 8) if $^O ne 'MSWin32';
		$xmlString .= $preStr;
	}
	$xmlString .= "</simple_blog_wrap>\n";

	#process the generated Blog file
	my $outP = $self->transform ($format,\$xmlString);

	if (not defined $outFile) { #if output file set to nothing, spit to STDOUT
		print $$outP;
	}
	else {
		open (OF, ">$self->{path}". $outFile);
		flock *OF,2 if $^O ne 'MSWin32';
		seek OF,0,0;       # rewind to the start
		truncate OF, 0;	# the file might shrink!
		print OF $$outP;
		close OF;
		flock (*OF, 8) if $^O ne 'MSWin32';
	}
	return $outP;
}

#this subroutine creates an archive output by opening 'bb.idx' and
#concatentating all the <simple_blog></simple_blog> files in the
#blogbase into a single string, and processing it $format as explained
#in the pod. Works nearly identical to gen_Blog_Current,
#except it gets all blogs, not just the 'n' most current.

sub render_all { my ($self, $format, $outFile) = @_;
	#read in the blog entries from the 'bb.idx' file
	open(BB, "$self->{blog_idx}") or die $self->{blog_idx};
	flock *BB,2 if $^O ne 'MSWin32';
	seek BB,0,0;       # rewind to the start
	truncate BB, 0;	# the file might shrink!
	my @getFiles;
	while (<BB>) {
		next if ($_ =~ /^\#/);
		my @tmp = split(/\t/, $_);
		push(@getFiles, $tmp[0]);
	}
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';

	#open the 'blog.xml' files individually and concatenate into xmlString
	my $xmlString = "<simple_blog_wrap>\n";
	for (@getFiles) {
		my $fil = $_;
		my $preStr;
		open (GF, "$fil") or die "$fil";
		flock *GF,2 if $^O ne 'MSWin32';
		seek GF,0,0;       # rewind to the start
		truncate GF, 0;	# the file might shrink!
		while (<GF>) { $preStr .= $_; }
		close GF;
		flock (*GF, 8) if $^O ne 'MSWin32';
		$xmlString .= $preStr;
	}
	$xmlString .= "</simple_blog_wrap>\n";

	#process the generated Blog file
	my $outP = $self->transform ($format,\$xmlString);

	if (not defined($outFile)) { #if output file not defined, spit to STDOUT
		print $$outP;
	}
	else {
		open (OF, ">$self->{path}". $outFile);
		flock *OF,2 if $^O ne 'MSWin32';
		seek OF,0,0;       # rewind to the start
		truncate OF, 0;	# the file might shrink!
		print OF $$outP;
		close OF;
		flock (*OF, 8) if $^O ne 'MSWin32';
	}
	return $outP;
}


# Transform XML to HTML
# Accepts: reference to a 'formatting' hash; reference to a string of XML
# Returns: reference to a string of HTML
sub transform { my ($self,$format,$xml) = (shift,shift,shift);
	if (not defined $format or ref $format ne 'HASH'){
		die "transform takes two arguments, the first being a hash reference for formatting";
	}
	if (not defined $xml or ref $xml ne 'SCALAR'){
		die "transform takes two arguments, the second being a scalar reference of XML";
	}
	my $open = {};
	my $html;
	foreach my $node (keys %$format){
		my $p    = HTML::TokeParser->new(\$format->{$node});
		my $html = "";
		while (my $t = $p->get_token){
			push @{$open->{$node}},"@$t[1]" if @$t[0] eq 'S';
		}
	}

	# warn "XML: $$xml\n\n";
	my $p = HTML::TokeParser->new($xml);
	my @current;
	while (my $t = $p->get_token){
		if (@$t[0] eq 'S'){
			# warn "Open ",@$t[1],"\n" if $^W;
			push @current, @$t[1];
			$html .= $format->{@$t[1]} if exists $format->{@$t[1]};
		}
		elsif (@$t[0] eq 'T'){
			# warn "Text @$t[1]","\n" if $^W;
			$html .= @$t[1] . $p->get_text;
		}
		elsif (@$t[0] eq 'E'){
			# warn "Close @$t[1] with ", join",",@{$open->{$current[$#current]}},"\n"  if $^W;
			$html .= join '',( map {"</$_>"} reverse @{$open->{$current[$#current]}}) if $open->{$current[$#current]};
			pop @current;
		}
	}
	return \$html;
}


1;
__END__


=head1 SEE ALSO

See L<Blog::Simple>, L<HTML::TokeParser>.

=head1 AUTHOR

Lee Goddard (lgoddard -at- cpan -dot- org),
based on work by J. A. Robson, E<lt>gilad@arbingersys.comE<gt>

=head1 COPYRIGHT

This module: Copyright (C) Lee Goddard, 2003. All Rights Reserved.
Made available under the same terms as Perl itself.

=cut

