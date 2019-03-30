{$INCLUDE valkyrie.inc}
// @abstract(XML utilities wrapper class for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(May 7, 2004)
// @cvs($Author: chaos-dev $)
// @cvs($Date: 2008-01-14 22:16:41 +0100 (Mon, 14 Jan 2008) $)
//
//  @html <div class="license">
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the GNU Library General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or (at your
//  option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
//  for more details.
//
//  You should have received a copy of the GNU Library General Public License
//  along with this library; if not, write to the Free Software Foundation,
//  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//  @html </div>

unit vxml;
interface
uses DOM, XPath;

type TVXMLDocument = class(TXMLDocument)
  function GetElement( aXPathQuery: string; aContext: TDOMNode = nil ): TDOMElement;
  function GetAttribute( aXPathQuery, aAttribute: string; aContext: TDOMNode = nil ): string;
end;

implementation

uses sysutils;

function TVXMLDocument.GetElement( aXPathQuery: string; aContext: TDOMNode ): TDOMElement;
var iXPathResult : TXPathVariable;
begin
try
  if aContext = nil then aContext := Self;
  iXPathResult := EvaluateXPathExpression(aXPathQuery, aContext);
  if (iXPathResult = nil) or (iXPathResult.AsNodeSet().First = nil) then
  begin
    FreeAndNil(iXPathResult);
    Exit(nil);
  end;
  GetElement := TDOMElement(iXPathResult.AsNodeSet().First);
  FreeAndNil( iXPathResult );
except
  on e : Exception do
  begin
    e.Message := e.Message + ' ("'+aXPathQuery+'")';
    raise;
  end;
end;
end;

function TVXMLDocument.GetAttribute(aXPathQuery, aAttribute: string; aContext: TDOMNode) : string;
var iXMLElement  : TDOMElement;
begin
  if aContext = nil then aContext := Self;
  iXMLElement := GetElement( aXPathQuery, aContext );
  if (iXMLElement = nil) then Exit('') else Exit( iXMLElement.GetAttribute(aAttribute) );
end;



end.

