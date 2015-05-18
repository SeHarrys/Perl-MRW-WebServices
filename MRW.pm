package MRW;

=doc
    MRW : Modulo SAGEC
=cut

use Data::Dumper;
use Mojo::UserAgent;
use Time::HiRes 'gettimeofday';
use POSIX::strftime::GNU;
use POSIX 'strftime';
use MIME::Base64;
use XML::Simple;

use feature 'say';

sub new {
    my $class = shift;
    my $config = shift;
    my $self;

    map { $self->{mrw}->{$_} = $config->{$_} } keys %{ $config };

    $self = bless $self, $class;

    return $self;
}

=head2
    Formato: FFFFFAAAAAAYYYYMMDDhhmmssnnn (length:28)
=cut
sub NumeroSolicitud {
    my $self = shift;

    my ($t, $nsec) = gettimeofday;
    $nsec = substr($nsec,3);

    my @t = localtime $t;
    my $fecha = strftime "%Y%m%d%H%M%S", localtime $t; 
    
    my $str = qq{$self->{mrw}->{CodigoFranquicia}$self->{mrw}->{CodigoAbonado}$fecha$nsec};

    return $str;
}

=head2
    Codigos de servicio
=cut
sub CodigoServicio {
    my $self = shift;
    my $tipo = shift;
    my $ret;
    
    my $codes = {
	'0005' => 'Urgente hoy',
	'0010' => 'Promociones',
	'0100' => 'Urgente 12',
	'0110' => 'Urgente 14',
	'0120' => 'Urgente 22',
	'0200' => 'Urgente 19',
	'0205' => 'Urgente 19 Expedicion',
	'0210' => 'Urgente 19 Mas 40 Kilos',
	'0220' => '48 Horas Portugal',
	'0230' => 'Bag 19',
	'0235' => 'Bag 14',
	'0300' => 'Economico',
	'0310' => 'Economico Mas 40 Kilos',
	'0350' => 'Economico Interinsular',
	'0400' => 'Express Documentos',
	'0450' => 'Express 2 Kilos',
	'0480' => 'Caja Express 3 Kilos',
	'0490' => 'Documentos 14',
	'0800' => 'Ecommerce',
	'0810' => 'Ecommerce Canje',
    };

    map { $ret = $_ if $codes->{$_} eq $tipo } keys %{$codes};
    
    unless ( $ret ) {
	say "CodigoServicio no valido : $tipo";
	return '0200';
    }
    
    return $ret;
}

=head2
    AuthInfo Header
=cut
sub AuthInfo {
    my $self = shift;
    my $str;

    $str = '<soap:Header>
	<mrw:AuthInfo>
	<mrw:CodigoFranquicia>'.$self->{mrw}->{CodigoFranquicia}.'</mrw:CodigoFranquicia>
	<mrw:CodigoAbonado>'.$self->{mrw}->{CodigoAbonado}.'</mrw:CodigoAbonado>
	<mrw:CodigoDepartamento></mrw:CodigoDepartamento>
	<mrw:UserName>'.$self->{mrw}->{UserName}.'</mrw:UserName>
	<mrw:Password>'.$self->{mrw}->{Password}.'</mrw:Password>
	</mrw:AuthInfo>
	</soap:Header>';
	
    return $str;
}

=head2
    Metodo que se usa para la Transmision del envio

    Hasta implementar WSDL real no esta chapuza usar GenMethods para regenerar struct

    Opcional: 'DatosRecogida'
=cut
sub TransmEnvio {
    my $self  = shift;
    my $Envio = shift;

    my $Fecha = strftime "%d/%m/%Y", localtime;

    ## TransmEnvioRequest
    my $Req = {
	'DatosEntrega' => {
	    'Telefono'      => $Envio->{DatosEntrega}->{Telefono},
	    'Nif'           => $Envio->{DatosEntrega}->{Nif},
	    'Nombre'        => $Envio->{DatosEntrega}->{Nombre},
	    'Observaciones' => $Envio->{DatosEntrega}->{Observaciones},
	    'Contacto'      => $Envio->{DatosEntrega}->{Contacto},
	    'ALaAtencionDe' => $Envio->{DatosEntrega}->{ALaAtencionDe},
	    'Direccion'     => {
		CodigoTipoVia => '',
		Via           => $Envio->{DatosEntrega}->{Direccion}->{Via},
		Numero        => $Envio->{DatosEntrega}->{Direccion}->{Numero},
		Resto         => '',
		CodigoPostal  => $Envio->{DatosEntrega}->{Direccion}->{CodigoPostal},
		Poblacion     => $Envio->{DatosEntrega}->{Direccion}->{Poblacion},
	    },
	},
	'DatosServicio' => {
	    'SeguroOpcional'        => '',
	    'Notificaciones'        => {
		CanalNotificacion => $Envio->{DatosServicio}->{Notificaciones}->{CanalNotificacion},
		TipoNotificacion  => $Envio->{DatosServicio}->{Notificaciones}->{TipoNotificacion},
		MailSMS           => $Envio->{DatosServicio}->{Notificaciones}->{MailSMS},
	    },
	    'Frecuencia'            => '',
	    'Entrega830'            => 'N',
	    'ConfirmacionInmediata' => '',
	    'DescripcionServicio'   => '',
	    'NumeroPuentes'         => '',
	    'EntregaPartirDe'       => '',
	    'Retorno'               => 'N',
	    'Bultos'                => $Envio->{DatosServicio}->{Bultos},
	    'TipoMercancia'         => '',
	    'Reembolso'             => $Envio->{DatosServicio}->{Reembolso},
	    'ImporteReembolso'      => $Envio->{DatosServicio}->{ImporteReembolso},
	    'Fecha'                 => $Fecha,
	    'ValorEstadisticoEuros' => '',
	    'TramoHorario'          => '',
	    'EntregaSabado'         => $Envio->{DatosServicio}->{EntregaSabado},
	    'NumeroAlbaran'         => '',
	    'Peso'                  => $Envio->{DatosServicio}->{Peso},
	    'NumeroBultos'          => $Envio->{DatosServicio}->{NumeroBultos},
	    'CodigoPromocion'       => '',
	    'Mascara_Campos'        => '',
	    'Mascara_Tipos'         => '',
	    'ValorDeclarado'        => '',
	    'Referencia'            => $Envio->{DatosServicio}->{Referencia},
	    'ServicioEspecial'      => '',
	    'CodigoMoneda'          => '',
	    'NumeroSobre'           => '',
	    'EnFranquicia'          => 'N',
	    'ValorEstadistico'      => '',
	    'Asistente'             => '',
	    'Gestion'               => '',
	    'CodigoServicio'        => $self->CodigoServicio('Urgente 19'),
	    'PortesDebidos'         => '',
	},
    };

    return $self->WS($self->MakeStruct($Req));
}

=head2
    Genera la estructura para el call
=cut
sub GetMethods {
    my $S = XMLin(shift);

    for my $K ( keys %{$S->{request}} ) {
	say "'$K' => {";
	for my $E ( keys %{$S->{request}{$K}} ) {
	    say "\t'$E' => '',";
	}
	say "}";
    }
    
}

=head2

=cut
sub MakeStruct {
    my $self = shift;
    my $S    = shift;
    my $str  = '<soap:Body><mrw:TransmEnvio><mrw:request>';

    for my $K ( keys %{$S} ) {
	$str .= "<mrw:$K>\n";
	for my $E ( keys %{$S->{$K}} ) {

	    if ( $E eq 'Bultos' ) {
		$str .= $self->MakeBultos($S->{$K}->{Bultos});
	    } elsif  ( ref $S->{$K}->{$E} eq 'HASH' ) {
		$str .= $self->ForData($E,$S->{$K}->{$E});
	    } else {
		$str .= "\t<mrw:$E>".$S->{$K}->{$E}."</mrw:$E>\n";
	    }
	    
	}
	$str .= "</mrw:$K>\n";
    }

    $str .= '</mrw:request></mrw:TransmEnvio></soap:Body></soap:Envelope>';
    
    return $str;
}

sub ForData {
    my $self = shift;
    my $E = shift;
    my $s = shift;
    
    my $string = "\t<mrw:$E>\n";
    
    for my $E ( keys %{$s} ) {
	$string .= "\t\t<mrw:$E>".$s->{$E}."</mrw:$E>\n";
    }

    $string .= "\t</mrw:$E>\n";
    
    return $string;
}
    
sub WS {
    my $self   = shift;
    my $struct = shift;
    
    my $ua = Mojo::UserAgent->new;

    my $message = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:mrw="http://www.mrw.es/">';

    $message .= $self->AuthInfo();
    $message .= $struct;

    my $XML = $self->Post($message);
    #my $XML = XMLin( $ua->post( $self->{mrw}->{WSDL} => {'Content-Type' => 'text/xml' } => $message)->res->body );

    my $Info;
    
    for my $K ( keys %{$XML->{'soap:Body'}->{'TransmEnvioResponse'}->{'TransmEnvioResult'}} ) {
	$Info->{$K} = $XML->{'soap:Body'}->{'TransmEnvioResponse'}->{'TransmEnvioResult'}->{$K};
    }
    
     $Info->{UrlPanel} = qq{$self->{mrw}->{Panel}?Franq=$self->{mrw}->{CodigoFranquicia}&Ab=$self->{mrw}->{CodigoAbonado}&Dep=&Pwd=$self->{mrw}->{Password}&Usr=$self->{mrw}->{UserName}&NumEnv=$Info->{NumeroEnvio}};
    
    return $Info;
}

sub Post {
    my $self = shift;
    my $msg  = shift;

    my $ua = Mojo::UserAgent->new;

    my $XML = XMLin( $ua->post( $self->{mrw}->{WSDL} => {'Content-Type' => 'text/xml' } => $msg )->res->body );

    return $XML;
}

sub MakeBultos {
    my $self   = shift;
    my $Bultos = shift;
    
    my @map = qw(Alto Largo Ancho Dimension Referencia Peso);
    
    my $string = "<mrw:Bultos>\n";
    
    for my $B ( keys %{$Bultos} ) {
	$string .= "<mrw:BultoRequest>\n";
	
	for my $K ( keys %{$Bultos->{$B}} ) {
	    $string .= "\t<mrw:$K>".$Bultos->{$B}->{$K}."</mrw:$K>\n";
	}

	$string .= "</mrw:BultoRequest>\n";       
    }
    
    $string .= "</mrw:Bultos>\n";

    return $string;
}

sub EtiquetaEnvio {
    my $self  = shift;
    my $envio = shift;

    my $string = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:mrw="http://www.mrw.es/">';

    $string .= $self->AuthInfo();

    $string .= '<soap:Body>
	<mrw:GetEtiquetaEnvio>
	<mrw:request>
	<mrw:NumeroEnvio>'.$envio.'</mrw:NumeroEnvio>
	<mrw:SeparadorNumerosEnvio></mrw:SeparadorNumerosEnvio>
	<mrw:FechaInicioEnvio></mrw:FechaInicioEnvio>
	<mrw:FechaFinEnvio></mrw:FechaFinEnvio>
	<mrw:TipoEtiquetaEnvio>0</mrw:TipoEtiquetaEnvio>
	<mrw:ReportTopMargin>1100</mrw:ReportTopMargin>
	<mrw:ReportLeftMargin>650</mrw:ReportLeftMargin>
	</mrw:request>
	</mrw:GetEtiquetaEnvio>
	</soap:Body>
	</soap:Envelope>';

    my $XML = $self->Post($string);

    $self->SavePDF($envio,$XML->{'soap:Body'}->{GetEtiquetaEnvioResponse}->{GetEtiquetaEnvioResult}->{EtiquetaFile});

    return $XML;
}

sub SavePDF {
    my $self  = shift;
    my $Envio = shift;
    my $PDF   = shift;

    my $File = $self->{mrw}->{RutaPDF}.$Envio.'.pdf';

    say $File;
    
    open F,">$File";
    print F decode_base64($PDF);
    close F;
}

1;
