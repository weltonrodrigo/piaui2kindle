#!/usr/bin/perl 
#===============================================================================
#
#         FILE: scrap.pl
#
#        USAGE: ./scrap.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: WELTON RODRIGO TORRES NASCIMENTO (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 31-07-2012 12:06:35
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Scrappy;
use Template;
use IO::File;
use WWW::Mechanize::Cached;

binmode STDOUT, ":utf8";

my $tt = Template->new({INTERPOLATE => 1, ENCODING => 'utf8'})
		or die "$Template::ERROR\n";

my $io = IO::File->new();
my $scrappy = Scrappy->new;
$scrappy->{worker} = new WWW::Mechanize::Cached;
 
$scrappy->crawl('http://revistapiaui.estadao.com.br/outras-edicoes/sumario/edicao-64',
	'/outras-edicoes/sumario/edicao-64' => {
		'.conteudo li a' => sub {
			my ($self, $item) = @_;

			return if $item->{href} =~ /proxima-edicao/;

			#print "[ITEM] $item->{text}: $item->{href}\n";
			$self->queue->add($item->{href});
		}
	},
	'/edicao-64/:secao/:artigo' => {
		'p img' => sub {
			my ($self, $item, $args) = @_;

			return unless $args->{artigo} =~ /mitolo/;
			
			my ($dropcap) = $item->{src} =~ m{geral/(.)_*.gif};

			$item->{text} = uc $dropcap; 

		}, 
		'body' => sub {
			my ($self, $item, $args) = @_;
			 
			my $autor = $self
				->select('.autor p em')->data->[0]->{text};
			my $title = $self
				->select('//div[@class="article"]/div/h3')->data->[0]->{text};

			my @content;

			return unless $args->{artigo} =~ /mitolo/;
			foreach my $p ( @{$self ->select('.article_content p')->data} ){

				$p->{text} =~ s/[^[:print:]]//g;

				next if $p->{text} =~ /^\s*$/;
				push @content, $p;
			}

			my $vars = {
				title	=> $title, 
				content	=> \@content,
			};

			# Arquivo de saida.
			$io->open("> saida/$args->{artigo}.html");
			$io->binmode(":utf8");

			$tt->process('templates/artigo.tt', $vars, $io) or die $tt->error();

			$io->close();
			 
		}
	}
);

