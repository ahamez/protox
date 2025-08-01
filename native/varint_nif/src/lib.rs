use rustler::{Binary, Env, OwnedBinary};

rustler::init!("Elixir.Protox.Varint.Native", [encode, decode]);

#[rustler::nif(schedule = "DirtyCpu")]
pub fn encode<'a>(env: Env<'a>, value: u64) -> (Binary<'a>, usize) {
    let mut v = value;
    let mut bytes = Vec::new();
    while v >= 0x80 {
        bytes.push(((v as u8) & 0x7f) | 0x80);
        v >>= 7;
    }
    bytes.push(v as u8);
    let len = bytes.len();
    let mut ob = OwnedBinary::new(len).unwrap();
    ob.as_mut_slice().copy_from_slice(&bytes);
    (ob.release(env), len)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode<'a>(env: Env<'a>, data: Binary<'a>) -> rustler::NifResult<(u64, Binary<'a>)> {
    let bytes = data.as_slice();
    let mut result: u64 = 0;
    let mut shift = 0;
    let mut i = 0;
    while i < bytes.len() {
        let b = bytes[i];
        result |= ((b & 0x7f) as u64) << shift;
        i += 1;
        if b & 0x80 == 0 {
            let mut ob = OwnedBinary::new(bytes.len() - i).unwrap();
            ob.as_mut_slice().copy_from_slice(&bytes[i..]);
            return Ok((result, ob.release(env)));
        }
        shift += 7;
        if shift > 64 {
            break;
        }
    }
    Err(rustler::Error::Atom("invalid_varint"))
}
