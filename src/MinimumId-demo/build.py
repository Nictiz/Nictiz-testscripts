#!/usr/bin/env python3
"""Build standalone R5 demo TestScripts with R4 XML/XML and JSON/JSON fixtures.

Run: python3 src/MinimumId-demo/build.py
The rich Patient content is derived from the existing BgZ / MI-089 example.
"""
import copy
import json
from pathlib import Path
from xml.etree import ElementTree as ET

HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parents[1] / 'output/R4/MinimumId-demo'
EXT = 'http://fhir.interoplab.eu/fhir/StructureDefinition/Interoplab-CL-ext-minimumId-'
DAR = {'extension': [{'url': 'http://hl7.org/fhir/StructureDefinition/data-absent-reason', 'valueCode': 'unknown'}]}


def instruction(name):
    return {'url': EXT + name, 'valueBoolean': True}


def rules(*names):
    return {'extension': [instruction(n) for n in names]}


def choice(datatype, *options):
    return {'extension': [{'url': EXT + 'choice', 'extension': [
        {'url': 'option', 'value' + datatype: option} for option in options]}]}


def xml(resource):
    # Ordering is significant for FHIR XML; primitive metadata shares its element.
    orders = {
        'Patient': 'id meta implicitRules language text contained extension modifierExtension identifier active name telecom gender birthDate deceasedBoolean deceasedDateTime address maritalStatus multipleBirthBoolean multipleBirthInteger contact communication generalPractitioner managingOrganization link',
        'Bundle': 'id meta type total link entry',
        'entry': 'fullUrl resource search request response',
        'identifier': 'id extension use type system value period assigner',
        'name': 'id extension use text family given prefix suffix period',
        'telecom': 'id extension system value use rank period',
        'address': 'id extension use type text line city district state postalCode country period',
        'contact': 'id extension modifierExtension relationship name telecom address gender organization period',
        'coding': 'id extension system version code display userSelected',
        'communication': 'id extension modifierExtension language preferred',
        'generalPractitioner': 'id extension reference type identifier display',
    }

    def children(node, data, kind):
        keys = list(dict.fromkeys(k.removeprefix('_') for k in data if k != 'resourceType'))
        order = orders.get(kind)
        if order:
            assert set(keys) <= set(order.split()), (kind, keys)
            keys = [k for k in order.split() if k in keys]
        for key in keys:
            if key == 'url' and kind == 'extension' or key == 'id' and 'resourceType' not in data:
                node.set(key, data[key])
            else:
                add(node, key, data.get(key), data.get('_' + key))

    def add(parent, key, value, metadata=None):
        if isinstance(value, list) or isinstance(metadata, list):
            values, metas = value or [], metadata or []
            for i in range(max(len(values), len(metas))):
                v = values[i] if i < len(values) else None
                m = metas[i] if i < len(metas) else None
                if v is not None or m:
                    add(parent, key, v, m)
            return
        node = ET.SubElement(parent, key)
        if isinstance(value, dict):
            if 'resourceType' in value:
                children(ET.SubElement(node, value['resourceType']), value, value['resourceType'])
            else:
                children(node, value, key)
        elif value is not None:
            node.set('value', str(value).lower() if isinstance(value, bool) else str(value))
        if metadata:
            children(node, metadata, key)

    root = ET.Element(resource['resourceType'], xmlns='http://hl7.org/fhir')
    children(root, resource, resource['resourceType'])
    ET.indent(root, space='  ')
    return ET.tostring(root, encoding='unicode') + '\n'


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')


VIEWER = ('Open Resource comparison op de minimumId-assert. Minimum fixture staat links, Source fixture rechts. '
          'Bekijk Match, Different, Missing en de instructielabels; navigeer vooruit en terug door de verschillen, '
          'klap geneste elementen in en uit en controleer de oorspronkelijke bronindices. '
          'Zet Show extra aan en uit: extra inhoud is toegestaan en wordt neutraal getoond. '
          'Beide panelen volgen het bronformaat; er is geen XML/JSON-toggle. '
          'Sla de Test run op en heropen de vergelijking: inhoud, status, uitleg en formaat blijven behouden.')


def operation(id_, interaction, **kwargs):
    return {'id': id_, 'description': f'Voer {interaction} uit met de eigen demobron',
            'type': {'system': 'http://hl7.org/fhir/restful-interaction', 'code': interaction},
            'origin': 1, 'destination': 1, 'encodeRequestUrl': True, **kwargs}


def check(id_, description, **kwargs):
    return {'assert': {'id': id_, 'description': description, 'warningOnly': False,
                       'stopTestOnFail': True, **kwargs}}


def build_case(number, title, status, description, variants, warning=False, invalid=False, variables=None):
    scope = f'MID-{number:02}'
    folder = OUTPUT / ('Ongeldige-instructies' if invalid else 'Client-Automated')
    folder.mkdir(parents=True, exist_ok=True)
    write_json(folder / 'properties.json', {
        'goal': 'Test', 'fhirVersion': 'R4', 'informationStandard': 'MinimumId demo',
        'category': 'Resource comparison', 'subcategory': 'Ongeldige instructies' if invalid else 'Demo',
        'role': {'name': 'Client-Automated'}, 'serverAlias': 'conformancelab'})
    script = {
        'resourceType': 'TestScript', 'id': scope,
        'meta': {'profile': ['http://fhir.interoplab.eu/fhir/StructureDefinition/Interoplab-CL-TestScript-core']},
        'url': 'http://fhir.interoplab.eu/demo/minimumId/TestScript/' + scope,
        'version': '1.0.0', 'name': f'MinimumIdDemo{number:02}',
        'title': f'{scope} / {title} / {status}', 'status': 'active', 'publisher': 'Interoplab',
        'description': 'Kies Automated mode en behoud de run-id. Alleen JSON/JSON en XML/XML. '
                       f'Verwachte scriptstatus: **{status}**.\n\n' + description + '\n\n' + VIEWER,
        'origin': [{'index': 1, 'profile': {'system': 'http://terminology.hl7.org/CodeSystem/testscript-profile-origin-types', 'code': 'FHIR-Client'}}],
        'destination': [{'index': 1, 'profile': {'system': 'http://fhir.interoplab.eu/fhir/CodeSystem/Interoplab-CL-destination-profile', 'code': 'Conformancelab-Server'}}],
        'variable': [{'name': scope + '-run', 'defaultValue': '${UUID}'}] + (variables or []),
        'fixture': [], 'setup': {'action': []}, 'test': [], 'teardown': {'action': []},
    }
    for variant, minimum, source, extra in variants:
        for fmt in ('json', 'xml'):
            key = f'{scope}-{variant}-{fmt}'
            rid = '${' + scope + '-run}-' + variant + '-' + fmt
            source = copy.deepcopy(source)
            source['id'] = rid
            for kind, data in (('minimum', minimum), ('source', source)):
                name = f'_fixtures/{scope}/{variant}-{kind}.{fmt}'
                path = folder / name
                path.parent.mkdir(parents=True, exist_ok=True)
                if fmt == 'json':
                    write_json(path, data)
                else:
                    path.write_text(xml(data))
                script['fixture'].append({'id': key + '-' + kind, 'autocreate': False, 'autodelete': False,
                                          'resource': {'reference': name}})
            resource = source['resourceType']
            url = '${DESTINATION-1}/' + resource + '/' + rid
            mime = 'application/fhir+' + fmt
            headers = [{'field': 'Content-Type', 'value': mime}, {'field': 'Accept', 'value': mime}]
            seed = operation(key + '-seed', 'update', url=url, sourceId=key + '-source', requestHeader=headers)
            script['setup']['action'] += [{'operation': seed}, check(key + '-seed-ok', 'Opslaan eigen bron: HTTP 200/201', responseCode='200,201', operator='in')]
            request = extra.get('direction') == 'request'
            op = (copy.deepcopy(seed) if request else operation(key + '-read', 'read', url=url + '?_format=' + fmt,
                  requestHeader=[{'field': 'Accept', 'value': mime}]))
            op['id'] = key + '-exchange'
            actions = [{'operation': op}, check(key + '-http', 'HTTP 200/201' if request else 'HTTP 200',
                       responseCode='200,201' if request else '200', operator='in' if request else 'equals'),
                       check(key + '-format', 'Controleer het ontvangen bronformaat ' + fmt.upper(),
                             direction='request' if request else 'response', headerField='Content-Type', operator='contains', value=mime),
                       check(key + '-result', f'Verwacht {status}: {variant}; open Resource comparison',
                             minimumId=key + '-minimum', warningOnly=warning, stopTestOnFail=False, **extra)]
            script['test'].append({'id': key, 'name': key, 'description': variant + ': ' + fmt.upper() + '/' + fmt.upper(), 'action': actions})
            script['teardown']['action'].append({'operation': operation(key + '-cleanup', 'delete', url=url)})
    write_json(folder / f'TestScript-{scope}.json', script)


def main():
    rich_min = json.loads((HERE / '_reference/rich-minimum.json').read_text())
    rich_source = json.loads((HERE / '_reference/rich-source.json').read_text())
    # Reverse repeated source items to make order-independent pairing visible.
    for field in ('identifier', 'name', 'telecom', 'address'):
        rich_source[field].reverse()
    build_case(1, 'Rijke patiënt, extra inhoud en lijstvolgorde', 'PASS',
               'Afgeleid van de BgZ-patiënt / MI-089: afgeschermd BSN, gekwalificeerde naamdelen, '
               'gewone en primitieve extensies, telecom, adres en uitgebreide contactpersoon. '
               'Alle minimumwaarden matchen; ids worden genegeerd. De bronlijsten staan omgekeerd. '
               'Show extra toont onder meer een dossieridentifier, oude naam, werktelefoon, werkadres en taalvoorkeur.',
               [('rijk', rich_min, rich_source, {})])

    instr_min = copy.deepcopy(rich_min)
    instr_source = copy.deepcopy(rich_source)
    instr_min['identifier'] = [rules('exists')]
    instr_min.pop('active'); instr_min['_active'] = rules('existsWithValue')
    instr_source['active'] = False
    instr_min.pop('birthDate'); instr_min['_birthDate'] = rules('exists')
    instr_source.pop('birthDate'); instr_source['_birthDate'] = DAR
    instr_min.pop('gender'); instr_min['_gender'] = choice('Code', 'male', 'female')
    instr_min.pop('multipleBirthBoolean'); instr_min['_multipleBirthInteger'] = rules('existsWithValue')
    instr_source.pop('multipleBirthBoolean'); instr_source['multipleBirthInteger'] = 0
    instr_min['maritalStatus'] = choice('CodeableConcept',
        {'coding': [{'system': 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus', 'code': 'M'}]},
        {'coding': [{'system': 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus', 'code': 'S'}]})
    instr_min['contact'] = [{**rules('optional'), 'name': {'_family': rules('exists'),
        'given': [None], '_given': [rules('existsWithValue')]}}]
    instr_source.pop('contact')
    instr_min['telecom'][0].setdefault('extension', []).append(instruction('optional'))
    build_case(2, 'Rijke patiënt met alle minimuminstructies', 'PASS',
               'Exists: identifier en extension-only birthDate zijn aanwezig. Value required: active=false en '
               'multipleBirthInteger=0 hebben een waarde. Choice: gender en de complete maritalStatus-optie matchen. '
               'Optional: de aanwezige telefoon voldoet; de afwezige contactouder heft zijn geneste eisen op. '
               'Controleer labels, opties en uitleg; instructie-extensies zijn geen vereiste bronextensies.',
               [('instructies', instr_min, instr_source, {})])

    compact_min = {
        'resourceType': 'Patient', 'identifier': [rules('exists')], 'active': True,
        'name': [{'use': 'official', 'family': 'Jansen', 'given': ['Anna', 'Maria'],
                  'prefix': ['dr.'], '_prefix': [rules('optional')],
                  'suffix': [None], '_suffix': [rules('existsWithValue')]}],
        'telecom': [rules('exists')], '_gender': choice('Code', 'male', 'female'),
        '_birthDate': rules('existsWithValue'), '_deceasedBoolean': rules('existsWithValue'),
        'address': [{'use': 'home', 'city': 'Utrecht', 'postalCode': '1234AB',
                     '_country': rules('exists'), 'state': 'UT', '_state': rules('optional')}],
        'maritalStatus': choice('CodeableConcept', {'coding': [{'system': 'urn:demo:s', 'code': 'A'}]},
                               {'coding': [{'system': 'urn:demo:t', 'code': 'B'}]}),
        '_multipleBirthInteger': rules('existsWithValue'),
        'contact': [{**rules('optional'), 'name': {'family': 'Jansen', '_given': [rules('existsWithValue')], 'given': [None]}}],
    }
    compact_source = {
        'resourceType': 'Patient', 'active': False,
        'name': [{'use': 'official', 'family': 'Janssen', 'given': ['Anna'], 'prefix': ['prof.'], '_suffix': [DAR], 'suffix': [None]}],
        'gender': 'unknown', '_birthDate': DAR, '_deceasedBoolean': DAR,
        'address': [{'use': 'home', 'city': 'Rotterdam', 'state': 'ZH'}],
        'maritalStatus': {'coding': [{'system': 'urn:demo:s', 'code': 'B'}]},
        '_multipleBirthInteger': DAR,
        'contact': [{'name': {'family': 'Jansen'}}],
        'communication': [{'language': {'text': 'Nederlands'}, 'preferred': True}],
    }
    absent = copy.deepcopy(compact_source)
    for field in ('gender', '_birthDate', '_deceasedBoolean', 'maritalStatus', '_multipleBirthInteger'):
        absent.pop(field)
    build_case(3, 'Compacte patiënt: Different en Missing', 'FAIL',
               '**Gevuld**: Different voor gewone waarden (active, family, city), aanwezige optional-waarden '
               '(prefix en state), Value required zonder waarde (birthDate, deceased, multipleBirth en suffix), '
               'primitive choice (gender) en complexe choice (maritalStatus: S/B is geen complete optie S/A of T/B). '
               'Missing voor exists op complex identifier/telecom en primitive country, gewone postcode en given Maria, '
               'en Value required op given binnen de aanwezige optional contactouder. '
               '**Afwezig**: aanvullend Missing voor primitive/complexe choice en Value required wanneer het hele element ontbreekt. '
               'Exists heeft bij een aanwezig element altijd succes; optional-afwezigheid is toegestaan. '
               'Beide bronnen blijven beknopt. Show extra toont de communicatie. Elke vergelijking verwacht FAIL.',
               [('gevuld', compact_min, compact_source, {}), ('afwezig', compact_min, absent, {})])
    build_case(4, 'Dezelfde compacte verschillen als waarschuwing', 'WARNING',
               'Dezelfde inhoudelijke verschillen als MID-03/gevuld, met warningOnly=true. '
               'De assert verwacht WARNING en behoudt dezelfde Resource comparison. Controleer de assertstatus afzonderlijk van de runaggregatie.',
               [('waarschuwing', compact_min, compact_source, {})], warning=True)
    build_case(5, 'Vergelijk de requestbody', 'PASS',
               'De test verstuurt de rijke patiënt met PUT. direction=request vergelijkt de daadwerkelijk verzonden '
               'requestbody met het rijke minimum. Controleer dat Source fixture de request is; standaard wordt de response gekozen.',
               [('request', rich_min, rich_source, {'direction': 'request'})])

    selected = copy.deepcopy(rich_source)
    selected['id'] = 'selected'
    bundle = {'resourceType': 'Bundle', 'type': 'collection', 'entry': [
        {'resource': {'resourceType': 'Patient', 'id': 'decoy', 'name': [{'family': 'Verkeerd'}]}},
        {'resource': selected}]}
    expression = "Bundle.entry.resource.where($this is Patient).where(id = 'selected')"
    build_case(6, 'Selecteer één rijke patiënt uit een Bundle', 'PASS',
               'De Bundle bevat eerst een afwijkende decoy en daarna de rijke selected-patiënt. '
               'expression selecteert precies die volledige Patient. Resource comparison toont de geselecteerde Patient; '
               'de Bundle en decoy mogen niet als bron worden vergeleken.',
               [('selectie', rich_min, bundle, {'expression': expression})])
    build_case(7, 'Variabelen in het minimum', 'PASS',
               'Het rijke minimum bevat ${MID-07-family}. De vaste variabele resolveert naar XXX_Helleman. '
               'Controleer de opgeloste waarde in Show variables en de gebruikte minimuminhoud in de vergelijking.',
               [('variabele', {**rich_min, 'name': [{**rich_min['name'][0], 'family': '${MID-07-family}'}]}, rich_source, {})],
               variables=[{'name': 'MID-07-family', 'defaultValue': 'XXX_Helleman'}])
    build_case(8, 'Selectiefouten zonder inhoudelijke vergelijking', 'ERROR',
               'Vier zelfstandige tests per formaat: geen geselecteerde resource, meerdere resources, een scalar '
               'in plaats van een Resource en een single()-evaluatiefout. Elke minimumId-assert verwacht zijn eigen '
               'herkenbare ERROR zonder inhoudelijke diff; HTTP- en formaatcontroles moeten slagen.',
               [(name, rich_min, bundle, {'expression': expr}) for name, expr in (
                   ('leeg', "Bundle.entry.resource.where(id = 'missing')"),
                   ('meervoudig', 'Bundle.entry.resource'),
                   ('scalar', expression + '.name.first().family'),
                   ('evaluatie', 'Bundle.entry.resource.single()'))])
    build_case(9, 'Ongeldige minimuminstructies', 'ERROR',
               'Afzonderlijke set: Sync kan deze bewust ongeldige minimumfixtures al afwijzen. Toon dan de specifieke '
               'Sync issues; er is geen runstatus bij importafwijzing. Als uitvoering wordt toegestaan: verwacht ERROR '
               'zonder Resource comparison, ook met warningOnly=true. Conflicterende instructies, Value required op '
               'een complex element en choice zonder opties zijn drie verschillende configuratiefouten.',
               [('conflict', {'resourceType': 'Patient', '_birthDate': rules('exists', 'existsWithValue')}, rich_source, {}),
                ('complex', {'resourceType': 'Patient', 'identifier': [rules('existsWithValue')]}, rich_source, {}),
                ('lege-choice', {'resourceType': 'Patient', 'maritalStatus': choice('CodeableConcept')}, rich_source, {})],
               warning=True, invalid=True)
    repeat_min = copy.deepcopy(rich_min)
    repeat_source = copy.deepcopy(rich_source)
    repeat_min['id'] = 'minimum-id-wordt-genegeerd'
    duplicate = {'system': 'urn:demo:dossier', 'value': 'A'}
    repeat_min['identifier'] += [copy.deepcopy(duplicate), copy.deepcopy(duplicate)]
    repeat_source['identifier'] += [copy.deepcopy(duplicate) for _ in range(3)]
    repeat_min['generalPractitioner'] = [{'reference': '#minimum-arts'}]
    repeat_source['generalPractitioner'] = [{'reference': '#bron-arts'}]
    # Contained resource ids and their local references are not literal requirements.
    repeat_min['contained'] = [{'resourceType': 'Practitioner', 'id': 'minimum-arts', 'active': True}]
    repeat_source['contained'] = [{'resourceType': 'Practitioner', 'id': 'bron-arts', 'active': True}]
    build_case(10, 'Duplicaten en niet gecontroleerde ids en lokale references', 'PASS',
               'Het rijke minimum vraagt twee identieke dossieridentifiers; de bron heeft er drie. '
               'Iedere minimumherhaling krijgt een eigen bronmatch; de derde is Extra. '
               'Verschillende root- en contained-resource-ids en #references verschijnen als Not checked. '
               'De overige contained-inhoud en rijke patiëntinhoud moeten wel matchen.',
               [('matching', repeat_min, repeat_source, {})])
    build_case(11, 'Compacte grensgevallen bij matching en typen', 'FAIL',
               'Vier losse vergelijkingen per formaat: twee identieke minimumidentifiers tegenover één bronitem '
               '(Missing); één vereiste S/A tegenover bronitems S/B en T/A (geen samenvoeging); '
               'deceasedBoolean tegenover deceasedDateTime (Different type); '
               'een absolute Practitioner-reference met _history/2 tegenover _history/3 (Different). '
               'Elke vergelijking verwacht FAIL; lokale #references uit MID-10 zijn afzonderlijk zichtbaar als Not checked.',
               [('duplicaat', {'resourceType': 'Patient', 'identifier': [duplicate, duplicate]},
                 {'resourceType': 'Patient', 'identifier': [duplicate]}, {}),
                ('niet-samenvoegen', {'resourceType': 'Patient', 'identifier': [{'system': 'urn:demo:s', 'value': 'A'}]},
                 {'resourceType': 'Patient', 'identifier': [{'system': 'urn:demo:s', 'value': 'B'}, {'system': 'urn:demo:t', 'value': 'A'}]}, {}),
                ('ander-type', {'resourceType': 'Patient', 'deceasedBoolean': False},
                 {'resourceType': 'Patient', 'deceasedDateTime': '2020-01-01'}, {}),
                ('reference', {'resourceType': 'Patient', 'generalPractitioner': [{'reference': 'https://example.org/fhir/Practitioner/1/_history/2'}]},
                 {'resourceType': 'Patient', 'generalPractitioner': [{'reference': 'https://example.org/fhir/Practitioner/1/_history/3'}]}, {})])
    print(f'Built 11 demo TestScripts in {OUTPUT}')


if __name__ == '__main__':
    main()
