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
use URI;
use Data::Dumper::Concise;

binmode STDOUT, ":utf8";

my $tt = Template->new({INTERPOLATE => 1, ENCODING => 'utf8'})
	or die "$Template::ERROR\n";

my $io = IO::File->new();
my $scrappy = Scrappy->new;
$scrappy->{worker} = new WWW::Mechanize::Cached;
$scrappy->debug(1);

my $base    = 'http://revistapiaui.estadao.com.br';
my $sumario = URI->new_abs('/outras-edicoes/sumario/edicao-', $base);
my $atual = 70;
 
# Para guardar informações de todas as edições;
my %edicoes;

# Agenda o crawling de todos os sumarios.
$scrappy->queue->add($sumario . $_) foreach (10..$atual-1);
 
# Inicia pela primeira edição.
$scrappy->crawl($scrappy->queue->next, 
	'/outras-edicoes/sumario/edicao-:edicao' => {
		'.conteudo li a' => sub {
			my ($self, $item, $args) = @_;

			# Alguns sumários contem um link para a próxima edição.
			return if $item->{href} =~ /proxima-edicao/;

			# Visitará todos os artigos deste edição e o sumário da próxima,
			# exceto pela edição atual, que é fechada para assinantes;
			$self->queue->add($item->{href});
		}
	},
	'/edicao-:edicao/:secao/:artigo' => {
		'body' => sub {
			my ($self, $item, $args) = @_;

			my $edicao = "edicao-" . $args->{edicao};
			my $secao = $args->{secao};
			my $autor = $self
				->select('.autor p em')->data->[0]->{text};
				
			my $title = $self
				->select('.article h3')->data->[0]->{text};
				
			my $subtitle = $self
				->select('p.subtitle')->data->[0]->{text};
				
			my $date  = $self
				->select('div.breadcrumbs div.flt-left')->data->[0]->{text};
			($date) = $date =~ /.*> (.*) $/; 
			
			my $article_img = URI->new_abs($self
				->select('.img_article')->data->[0]->{src}, $base);
			
			my $content = join "\n",
								map $_->{html},
									@{$self->select('.article_content p')->data};

			my $this = {
				'edicao' => $edicao, 
				'secao'  => $secao, 
				'autor'  => $autor, 
				'title'  => $title, 
				'subtitle' => $subtitle, 
				'date'   => $date, 
				'article_img' => $article_img, 
				'content' => $content
			};
			
			push @{ $edicoes{'edicao'} }, $this;
		}
	}
);

print Dumper \%edicoes;
