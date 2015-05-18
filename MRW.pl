#!/usr/bin/env perl

use MRW;
use Data::Dumper;
use JSON::XS;

use feature 'say';

sub OpenJSON {
    my $file = shift;
    
    local $/;
    open( my $fh, '<', $file );
    
    my $json_text   = <$fh>;
    my $perl_scalar = decode_json( $json_text );

    return $perl_scalar;
}

my $E = MRW->new(OpenJSON('config.json'));

my $Envio = OpenJSON('envio.json');

my $Info = $E->TransmEnvio($Envio);

my $PDF = $E->EtiquetaEnvio($Info->{NumeroEnvio});
